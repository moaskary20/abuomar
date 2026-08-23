#!/usr/bin/env python3
"""Scrape categories + products from aboomarpastry.com into JSON + local images."""

from __future__ import annotations

import json
import os
import random
import re
import string
import time
import urllib.error
import urllib.request
from html import unescape
from pathlib import Path

BASE = "https://aboomarpastry.com"
UA = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept-Language": "ar,en;q=0.8",
}
ROOT = Path(__file__).resolve().parents[1]
OUT_JSON = ROOT / "storage/app/imports/aboomar.json"
PUBLIC = ROOT / "storage/app/public"


def fetch(url: str, retries: int = 5) -> str:
    last = None
    for i in range(retries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=90) as resp:
                return resp.read().decode("utf-8", "ignore")
        except Exception as exc:  # noqa: BLE001
            last = exc
            time.sleep(1.5 * (i + 1))
    raise RuntimeError(f"fetch failed {url}: {last}")


def download(url: str, directory: str) -> str | None:
    if not url:
        return None
    PUBLIC.joinpath(directory).mkdir(parents=True, exist_ok=True)
    ext = Path(url.split("?")[0]).suffix or ".jpg"
    name = "".join(random.choices(string.ascii_lowercase + string.digits, k=40)) + ext.lower()
    rel = f"{directory}/{name}"
    dest = PUBLIC / rel
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=90) as resp:
                dest.write_bytes(resp.read())
            return rel
        except Exception:  # noqa: BLE001
            time.sleep(1.2 * (i + 1))
    print(f"  ! image failed: {url}")
    return None


def parse_categories(html: str) -> list[dict]:
    cats = []
    seen = set()
    for m in re.finditer(
        r'<a href="(https://aboomarpastry\.com/category/([^"]+))" class="text-dark p-4 d-flex align-items-center">([\s\S]*?)</a>',
        html,
    ):
        slug = m.group(2)
        if slug in seen:
            continue
        block = m.group(3)
        img = re.search(r'src="(https://aboomarpastry\.com/public/uploads/all/[^"]+)"', block)
        name_m = re.search(r'hov-text-primary"[^>]*>\s*([^<]+?)\s*<', block)
        if not name_m:
            continue
        seen.add(slug)
        cats.append(
            {
                "name": unescape(name_m.group(1).strip()),
                "slug": slug,
                "url": m.group(1),
                "image_url": img.group(1) if img else None,
            }
        )
    return cats


def parse_category_products(html: str) -> list[dict]:
    products = []
    seen = set()
    for m in re.finditer(
        r'<h3[\s\S]*?href="https://aboomarpastry\.com/product/([^"]+)"[^>]*>([^<]+)</a>[\s\S]*?<span class="fw-700 text-primary"[^>]*>\s*EGP\s*([\d,]+\.?\d*)\s*</span>',
        html,
    ):
        slug = m.group(1)
        if slug in seen:
            continue
        seen.add(slug)
        start = m.start()
        before = html[max(0, start - 3000) : start]
        imgs = re.findall(r'src="(https://aboomarpastry\.com/public/uploads/all/[^"]+)"', before)
        compare = None
        delm = re.search(r'<del[^>]*>\s*EGP\s*([\d,]+\.?\d*)\s*</del>', m.group(0))
        if delm:
            compare = float(delm.group(1).replace(",", ""))
        products.append(
            {
                "slug": slug,
                "name": unescape(m.group(2).strip()),
                "price": float(m.group(3).replace(",", "")),
                "compare_price": compare,
                "image_url": imgs[-1] if imgs else None,
            }
        )
    return products


def parse_product_page(html: str) -> dict:
    name = None
    m = re.search(r'property="og:title"\s+content="([^"]*)"', html)
    if m:
        name = unescape(m.group(1))
    m = re.search(r'<h2 class="[^"]*fs-16[^"]*fw-700[^"]*"[^>]*>\s*([^<]+)\s*</h2>', html)
    if m:
        name = unescape(m.group(1).strip())

    price = None
    m = re.search(r'property="product:price:amount"\s+content="([^"]+)"', html)
    if m:
        price = float(m.group(1).replace(",", ""))

    compare = None
    m = re.search(r'<del[^>]*>\s*EGP\s*([\d,]+\.?\d*)\s*</del>', html)
    if m:
        compare = float(m.group(1).replace(",", ""))

    quantity = 0
    m = re.search(r'id="available-quantity"[^>]*>\s*(\d+)', html)
    if m:
        quantity = int(m.group(1))

    external_id = None
    m = re.search(r'name="id"\s+value="(\d+)"', html)
    if m:
        external_id = m.group(1)

    gallery = []
    gm = re.search(r"product-gallery[\s\S]{0,8000}", html)
    if gm:
        gallery = list(
            dict.fromkeys(
                re.findall(
                    r'data-src="(https://aboomarpastry\.com/public/uploads/all/[^"]+)"',
                    gm.group(0),
                )
            )
        )

    description = None
    m = re.search(r'id="tab_default_1"[\s\S]*?aiz-editor-data"[^>]*>([\s\S]*?)</div>', html)
    if m:
        text = unescape(re.sub(r"<[^>]+>", "", m.group(1))).strip()
        description = text or None

    return {
        "name": name,
        "price": price,
        "compare_price": compare,
        "quantity": quantity,
        "external_id": external_id,
        "gallery_urls": gallery,
        "image_url": gallery[0] if gallery else None,
        "description": description,
    }


def main() -> None:
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    print("Fetching categories...")
    cats_html = fetch(f"{BASE}/categories")
    categories = parse_categories(cats_html)
    print(f"Found {len(categories)} categories")

    products_by_slug: dict[str, dict] = {}
    out_cats = []

    for idx, cat in enumerate(categories, 1):
        print(f"[{idx}/{len(categories)}] {cat['name']}")
        cat_image = download(cat["image_url"], "categories") if cat["image_url"] else None
        out_cats.append(
            {
                "name": cat["name"],
                "slug": cat["slug"],
                "image": cat_image,
                "sort_order": idx,
            }
        )

        try:
            page = fetch(cat["url"])
        except Exception as exc:  # noqa: BLE001
            print(f"  ! category page failed: {exc}")
            continue

        cards = parse_category_products(page)
        print(f"  products on page: {len(cards)}")

        for card in cards:
            slug = card["slug"]
            if slug in products_by_slug:
                if cat["slug"] == "-sqzr5":
                    products_by_slug[slug]["is_featured"] = True
                    products_by_slug[slug]["category_slug"] = "-sqzr5"
                continue

            details = {}
            try:
                details = parse_product_page(fetch(f"{BASE}/product/{slug}"))
                time.sleep(0.15)
            except Exception as exc:  # noqa: BLE001
                print(f"  ! product page {slug}: {exc}")

            main_url = details.get("image_url") or card.get("image_url")
            image = download(main_url, "products") if main_url else None
            gallery = []
            for gurl in details.get("gallery_urls") or []:
                if gurl == main_url:
                    continue
                path = download(gurl, "products/gallery")
                if path:
                    gallery.append(path)

            products_by_slug[slug] = {
                "name": details.get("name") or card["name"],
                "slug": slug,
                "sku": f"ABO-{details.get('external_id') or slug[:12].upper()}",
                "category_slug": cat["slug"],
                "price": details.get("price") if details.get("price") is not None else card["price"],
                "compare_price": details.get("compare_price")
                if details.get("compare_price") is not None
                else card.get("compare_price"),
                "quantity": details.get("quantity") or 0,
                "description": details.get("description"),
                "short_description": details.get("name") or card["name"],
                "image": image,
                "gallery": gallery or None,
                "is_featured": cat["slug"] == "-sqzr5",
            }
            print(f"  + {products_by_slug[slug]['name']} | {products_by_slug[slug]['price']} EGP")

        time.sleep(0.25)

    payload = {
        "categories": out_cats,
        "products": list(products_by_slug.values()),
    }
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Saved {OUT_JSON} ({len(out_cats)} categories, {len(products_by_slug)} products)")


if __name__ == "__main__":
    main()
