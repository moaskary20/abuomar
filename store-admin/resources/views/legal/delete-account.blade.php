@extends('legal.layout')

@section('title', 'Delete Account')
@section('description', 'How to delete your Helwany Abu Omar account and associated personal data, in line with Google Play account-deletion requirements.')
@section('canonical', url('/delete-account'))
@section('heading', 'Delete Account')

@section('meta')
    Effective date: {{ $effectiveDate }}<br>
    Official account-deletion page for the {{ $appName }} Android app
    (<span class="ar-name">{{ $appNameAr }}</span>, package {{ $packageName }}).
@endsection

@section('content')
        <nav class="toc" aria-label="Contents">
            <strong>Contents</strong>
            <ol>
                <li><a href="#request">How to request deletion</a></li>
                <li><a href="#deleted">Data we delete</a></li>
                <li><a href="#retained">Data we may retain</a></li>
                <li><a href="#time">Timeframe</a></li>
                <li><a href="#notes">Important notes</a></li>
                <li><a href="#contact">Contact</a></li>
            </ol>
        </nav>

        <p>
            Google Play requires apps that let you create an account to provide a way to request
            deletion of that account and the personal data linked to it. This page explains how to
            do that for {{ $appName }}. There is <strong>no fee</strong> to request deletion.
        </p>

        <h2 id="request">1. How to request deletion</h2>
        <div class="steps">
            <strong>Follow these steps</strong>
            <ol>
                <li>Use the email address registered on your {{ $appName }} account.</li>
                <li>Send a message with the subject line <strong>Delete my Helwany Abu Omar account</strong>.</li>
                <li>Include your full name and the phone number on the account so we can verify it is you.</li>
                <li>We will confirm the request and then delete the account and associated personal data as described below.</li>
            </ol>
        </div>

        <p>
            <a class="cta" href="{{ $deleteAccountMailto }}">Request deletion by email</a>
            <a class="cta secondary" href="https://wa.me/{{ $whatsAppIntl }}?text={{ rawurlencode('Please delete my Helwany Abu Omar account. Registered email: ') }}">Request by WhatsApp</a>
        </p>
        <p class="note">
            Uninstalling the app from your phone does <strong>not</strong> delete your account on our servers.
            You must send a deletion request using the steps above.
        </p>

        <h2 id="deleted">2. Data we delete</h2>
        <p>After we verify your request, we delete:</p>
        <ul>
            <li>Your customer account (name, email, phone, and hashed password)</li>
            <li>Saved delivery addresses</li>
            <li>Loyalty points and loyalty history tied to the account</li>
            <li>Favorite products</li>
            <li>Product reviews submitted from the account</li>
            <li>App sign-in tokens, so you are signed out on all devices</li>
        </ul>
        <p>
            Personal data stored only on your device (cart, app settings, and a local profile photo)
            is removed when you clear the app data or uninstall the app.
        </p>

        <h2 id="retained">3. Data we may retain</h2>
        <p>
            We may keep limited order records required for Egyptian commercial, tax, or dispute
            purposes (for example items ordered, amounts, and delivery status). Where we keep such
            records, we remove or anonymize personal identifiers that are not legally required,
            such as your login email and password.
        </p>
        <p>We do not keep your account so we can market to you after deletion.</p>

        <h2 id="time">4. Timeframe</h2>
        <p>
            We process verified deletion requests within <strong>30 days</strong>.
            There is no extra waiting period after confirmation, except the time needed to verify
            that the request comes from the account owner.
        </p>
        <p>
            If an order is still being prepared or delivered, we may complete that order first,
            then delete the account. We will tell you if this applies.
        </p>

        <h2 id="notes">5. Important notes</h2>
        <ul>
            <li>Deletion is permanent. You will need to create a new account if you use the app again.</li>
            <li>We verify identity using the registered email and the details you provide. We do not delete another person’s account based on an unverified request.</li>
            <li>This page is the official Google Play Account deletion URL for {{ $appName }}.</li>
            <li>See our <a href="{{ route('privacy-policy') }}">Privacy Policy</a> for how we collect and use data while your account exists.</li>
        </ul>

        <h2 id="contact">6. Contact</h2>
        <ul>
            <li>Email: <a href="mailto:{{ $contactEmail }}">{{ $contactEmail }}</a></li>
            <li>Phone: {{ $contactPhone }}</li>
            <li>WhatsApp: {{ $contactWhatsApp }}</li>
            <li>Website: <a href="{{ $websiteUrl }}">{{ $websiteUrl }}</a></li>
        </ul>
@endsection
