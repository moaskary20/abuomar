<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="index,follow">
    <title>@yield('title') | {{ $appName }}</title>
    <meta name="description" content="@yield('description')">
    <link rel="canonical" href="@yield('canonical')">
    <style>
        :root {
            --ink: #1f1712;
            --muted: #5c534c;
            --paper: #f7f1ea;
            --card: #fffdf9;
            --line: #e6d9cc;
            --teal: #0f766e;
            --teal-dark: #115e59;
            --cocoa: #7c4a2d;
        }
        * { box-sizing: border-box; }
        html { scroll-behavior: smooth; }
        body {
            margin: 0;
            font-family: Georgia, "Times New Roman", serif;
            color: var(--ink);
            background: var(--paper);
            line-height: 1.7;
        }
        header, main, footer { max-width: 820px; margin: 0 auto; padding: 0 20px; }
        header { padding-top: 36px; padding-bottom: 8px; }
        .brand {
            font-family: "Segoe UI", Tahoma, sans-serif;
            font-size: 13px;
            letter-spacing: .12em;
            text-transform: uppercase;
            color: var(--teal);
            font-weight: 700;
        }
        h1 {
            font-size: clamp(1.8rem, 4vw, 2.4rem);
            margin: 8px 0 6px;
            line-height: 1.2;
        }
        .meta {
            font-family: "Segoe UI", Tahoma, sans-serif;
            color: var(--muted);
            font-size: 14px;
            margin-bottom: 28px;
        }
        main {
            background: var(--card);
            border: 1px solid var(--line);
            border-radius: 18px;
            padding: 28px 28px 40px;
            margin-bottom: 32px;
            box-shadow: 0 10px 30px rgba(31, 23, 18, .04);
        }
        h2 {
            font-size: 1.15rem;
            margin-top: 28px;
            margin-bottom: 8px;
            color: var(--teal-dark);
        }
        p, li { font-size: 1.02rem; }
        ul, ol { padding-left: 1.2rem; }
        li { margin: 6px 0; }
        a { color: var(--teal-dark); }
        .toc, .steps {
            font-family: "Segoe UI", Tahoma, sans-serif;
            background: #f3ebe3;
            border-radius: 12px;
            padding: 16px 18px;
            font-size: 14px;
        }
        .toc a { text-decoration: none; }
        .toc ol, .steps ol { margin: 8px 0 0; padding-left: 1.2rem; }
        .steps { font-size: 15px; }
        .steps strong { font-size: 15px; }
        .cta {
            display: inline-block;
            font-family: "Segoe UI", Tahoma, sans-serif;
            background: var(--teal-dark);
            color: #fff;
            text-decoration: none;
            padding: 12px 18px;
            border-radius: 10px;
            font-weight: 600;
            margin: 8px 8px 8px 0;
        }
        .cta.secondary {
            background: transparent;
            color: var(--teal-dark);
            border: 1px solid var(--teal-dark);
        }
        footer {
            font-family: "Segoe UI", Tahoma, sans-serif;
            font-size: 13px;
            color: var(--muted);
            padding-bottom: 40px;
        }
        footer a { margin-right: 12px; }
        .ar-name { color: var(--cocoa); font-family: "Segoe UI", Tahoma, sans-serif; }
        .note {
            font-family: "Segoe UI", Tahoma, sans-serif;
            font-size: 14px;
            color: var(--muted);
            border-left: 3px solid var(--teal);
            padding-left: 12px;
        }
    </style>
</head>
<body>
    <header>
        <div class="brand">{{ $appName }}</div>
        <h1>@yield('heading')</h1>
        <p class="meta">@yield('meta')</p>
    </header>

    <main>
        @yield('content')
    </main>

    <footer>
        &copy; {{ date('Y') }} {{ $appName }}. All rights reserved.
        <a href="{{ route('privacy-policy') }}">Privacy Policy</a>
        <a href="{{ route('delete-account') }}">Delete account</a>
    </footer>
</body>
</html>
