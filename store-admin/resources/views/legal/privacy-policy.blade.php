@extends('legal.layout')

@section('title', 'Privacy Policy')
@section('description', 'Privacy Policy for the Helwany Abu Omar mobile app and online store. Explains what data we collect, how we use it, and your rights.')
@section('canonical', url('/privacy-policy'))
@section('heading', 'Privacy Policy')

@section('meta')
    Effective date: {{ $effectiveDate }}<br>
    Applies to the {{ $appName }} mobile application (<span class="ar-name">{{ $appNameAr }}</span>)
    and the website at <a href="{{ $websiteUrl }}">{{ $websiteUrl }}</a>.
@endsection

@section('content')
        <nav class="toc" aria-label="Contents">
            <strong>Contents</strong>
            <ol>
                <li><a href="#who">Who we are</a></li>
                <li><a href="#scope">Scope</a></li>
                <li><a href="#collect">Information we collect</a></li>
                <li><a href="#permissions">Device permissions</a></li>
                <li><a href="#use">How we use information</a></li>
                <li><a href="#share">How we share information</a></li>
                <li><a href="#retention">Data retention</a></li>
                <li><a href="#security">Security</a></li>
                <li><a href="#rights">Your rights and choices</a></li>
                <li><a href="#children">Children’s privacy</a></li>
                <li><a href="#transfers">International transfers</a></li>
                <li><a href="#changes">Changes to this policy</a></li>
                <li><a href="#contact">Contact us</a></li>
            </ol>
        </nav>

        <h2 id="who">1. Who we are</h2>
        <p>
            This Privacy Policy is issued by <strong>{{ $appName }}</strong> (“we”, “us”, or “our”),
            a pastry and confectionery store operating in Egypt. We provide an Android mobile app
            (package name: <code>{{ $packageName }}</code>) and related online services so customers
            can browse products, create an account, place orders, and manage delivery addresses.
        </p>
        <p>
            Google Play requires a publicly available privacy policy that describes how an app
            handles user data. This page is that policy.
        </p>

        <h2 id="scope">2. Scope</h2>
        <p>This policy covers personal data processed when you:</p>
        <ul>
            <li>Download, install, or use the {{ $appName }} app from Google Play</li>
            <li>Visit our website or API hosted at {{ $websiteUrl }}</li>
            <li>Create an account, place an order, contact customer support, or use loyalty features</li>
        </ul>
        <p>
            You can browse the product catalog without an account. An account is required to complete
            an order, save addresses, use favorites, and view loyalty points.
        </p>

        <h2 id="collect">3. Information we collect</h2>
        <p>We collect the following categories of information, depending on how you use the app:</p>

        <h2>3.1 Account information</h2>
        <ul>
            <li>Full name</li>
            <li>Email address</li>
            <li>Mobile phone number</li>
            <li>Password (stored in hashed form; we cannot read your plain-text password)</li>
        </ul>

        <h2>3.2 Order and delivery information</h2>
        <ul>
            <li>Delivery addresses (city, street, and contact phone you enter)</li>
            <li>Order contents, quantities, prices, coupons, and order status</li>
            <li>Payment method selected in the app (currently cash on delivery unless another method is enabled by the store)</li>
            <li>Loyalty points earned or redeemed, and product reviews you submit</li>
            <li>Saved favorite products</li>
        </ul>
        <p>
            We do not collect or store credit-card or debit-card numbers in the app. If a third-party
            payment provider is enabled later, that provider’s own privacy policy will apply to card data.
        </p>

        <h2>3.3 Optional profile photo</h2>
        <p>
            If you choose a profile picture, the app may access the camera or photo library.
            The photo is stored on your device for display in the app. We do not currently upload
            profile photos to our servers.
        </p>

        <h2>3.4 Technical and usage information</h2>
        <ul>
            <li>Authentication tokens needed to keep you signed in</li>
            <li>App settings and preferences stored on your device (for example language, notifications, and cart)</li>
            <li>Approximate technical logs created by our hosting provider (such as IP address, date/time, and request URL) for security, fraud prevention, and service reliability</li>
        </ul>
        <p>
            We do not currently use third-party advertising SDKs, analytics SDKs (such as Google Analytics or Firebase Analytics), or crash-reporting SDKs in the app.
            In-app toggles for “analytics” or “share location” are stored as preferences on your device and are not used to send GPS coordinates or advertising identifiers to us at this time.
        </p>
        <p>
            Delivery location is based on the address you type, not on live GPS tracking.
        </p>

        <h2 id="permissions">4. Device permissions</h2>
        <p>The Android app may request the following permissions:</p>
        <ul>
            <li><strong>Internet:</strong> to load the catalog, sign in, and submit orders to our server.</li>
            <li><strong>Camera:</strong> only if you choose to take a profile photo. This permission is optional.</li>
            <li><strong>Photos / storage:</strong> only if you choose a profile photo from your gallery. This permission is optional.</li>
        </ul>
        <p>
            Denying camera or photo access does not prevent you from browsing products or placing orders.
            You can change permissions in Android settings at any time.
        </p>

        <h2 id="use">5. How we use information</h2>
        <p>We use personal data to:</p>
        <ul>
            <li>Create and manage your customer account</li>
            <li>Process, confirm, prepare, and deliver orders</li>
            <li>Contact you about an order (phone, WhatsApp, or email)</li>
            <li>Apply coupons and operate the loyalty-points program</li>
            <li>Provide customer support and respond to complaints</li>
            <li>Improve product availability, app performance, and store operations</li>
            <li>Protect against fraud, abuse, and unauthorized access</li>
            <li>Comply with applicable Egyptian law and Google Play policies</li>
        </ul>
        <p>We do <strong>not</strong> sell your personal information.</p>

        <h2 id="share">6. How we share information</h2>
        <p>We share personal data only as needed to operate the store:</p>
        <ul>
            <li><strong>Delivery staff or partners:</strong> name, phone, and delivery address required to complete an order.</li>
            <li><strong>Hosting and infrastructure:</strong> our website and API are hosted with our service provider and may pass through Cloudflare for security and content delivery. These providers process data on our instructions.</li>
            <li><strong>Google Play:</strong> Google may collect its own device, install, and crash information under Google’s privacy policy when you download or use apps from Play.</li>
            <li><strong>Legal requests:</strong> we may disclose information if required by law, court order, or to protect our rights, customers, or the public.</li>
        </ul>
        <p>We do not share your data with third parties for their independent marketing.</p>

        <h2 id="retention">7. Data retention</h2>
        <p>
            We keep account, order, and loyalty records for as long as your account is active and as
            needed for accounting, delivery disputes, and legal obligations. You may request deletion
            of your account on our
            <a href="{{ route('delete-account') }}">Delete account</a> page.
            Some records may be retained in anonymized or aggregated form, or where we must keep them
            under Egyptian commercial or tax rules.
        </p>
        <p>
            Data stored only on your device (cart, settings, local profile photo) remains until you
            clear app data, uninstall the app, or delete it in the app.
        </p>

        <h2 id="security">8. Security</h2>
        <p>
            We use reasonable technical and organizational measures, including hashed passwords,
            HTTPS encryption in transit, and access controls on the store admin panel.
            No method of transmission or storage is 100% secure. Please keep your password confidential.
        </p>

        <h2 id="rights">9. Your rights and choices</h2>
        <p>Subject to applicable law, you may:</p>
        <ul>
            <li>Access or update the name, email, phone, and addresses in your account</li>
            <li>Request a copy of the personal data we hold about you</li>
            <li>Request correction of inaccurate data</li>
            <li>Request deletion of your account and associated personal data</li>
            <li>Withdraw optional permissions (camera/photos) in Android settings</li>
            <li>Stop using the app and uninstall it at any time</li>
        </ul>
        <p>
            To delete your account, follow the steps on
            <a href="{{ route('delete-account') }}">{{ url('/delete-account') }}</a>.
            For other access or correction requests, email
            <a href="mailto:{{ $contactEmail }}">{{ $contactEmail }}</a>
            from the email address registered on your account.
        </p>

        <h2 id="children">10. Children’s privacy</h2>
        <p>
            The {{ $appName }} app is intended for general audiences and is not directed to children
            under 13. We do not knowingly collect personal data from children under 13.
            If you believe a child has provided personal data, contact us and we will delete it.
            The app is not part of the Google Play Families program and is not designed for use by children.
        </p>

        <h2 id="transfers">11. International transfers</h2>
        <p>
            Our store serves customers in Egypt. The app backend may be hosted outside Egypt
            (including the United Kingdom, as reflected in our current website domain).
            Where data is processed outside Egypt, we take steps appropriate to the hosting arrangement
            to keep it secure and used only for the purposes in this policy.
        </p>

        <h2 id="changes">12. Changes to this policy</h2>
        <p>
            We may update this Privacy Policy from time to time. The “Effective date” at the top
            will change when we do. The latest version will always be available at
            <a href="{{ url('/privacy-policy') }}">{{ url('/privacy-policy') }}</a>.
            Continued use of the app after an update means you accept the revised policy.
        </p>

        <h2 id="contact">13. Contact us</h2>
        <p>Questions about privacy, data, or this policy:</p>
        <ul>
            <li>Store: {{ $appName }} (<span class="ar-name">{{ $appNameAr }}</span>)</li>
            <li>Email: <a href="mailto:{{ $contactEmail }}">{{ $contactEmail }}</a></li>
            <li>Phone: {{ $contactPhone }}</li>
            <li>WhatsApp: {{ $contactWhatsApp }}</li>
            <li>Website: <a href="{{ $websiteUrl }}">{{ $websiteUrl }}</a></li>
        </ul>
        <p>
            For Google Play listing purposes, this page is the official Privacy Policy URL for the
            {{ $appName }} Android application.
        </p>
@endsection
