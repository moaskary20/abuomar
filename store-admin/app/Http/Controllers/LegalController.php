<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class LegalController extends Controller
{
    public function privacyPolicy(): View
    {
        return view('legal.privacy-policy', [
            'appName' => 'Helwany Abu Omar',
            'appNameAr' => 'حلوانى ابوعمر',
            'packageName' => 'com.aboomar.pastry.store_mobile',
            'effectiveDate' => '25 August 2026',
            'contactEmail' => 'info@aboomarpastry.com',
            'contactPhone' => '15548',
            'contactWhatsApp' => '01270163333',
            'websiteUrl' => 'https://abouomar.caesar-agency.co.uk',
        ]);
    }
}
