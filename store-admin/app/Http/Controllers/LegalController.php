<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class LegalController extends Controller
{
    public function privacyPolicy(): View
    {
        return view('legal.privacy-policy', $this->legalPageData());
    }

    public function deleteAccount(): View
    {
        return view('legal.delete-account', $this->legalPageData());
    }

    /**
     * @return array<string, string>
     */
    private function legalPageData(): array
    {
        $contactEmail = 'info@aboomarpastry.com';
        $whatsApp = '01270163333';
        $whatsAppIntl = '201270163333';

        return [
            'appName' => 'Helwany Abu Omar',
            'appNameAr' => 'حلوانى ابوعمر',
            'packageName' => 'com.aboomar.pastry.store_mobile',
            'effectiveDate' => '25 August 2026',
            'contactEmail' => $contactEmail,
            'contactPhone' => '15548',
            'contactWhatsApp' => $whatsApp,
            'whatsAppIntl' => $whatsAppIntl,
            'websiteUrl' => 'https://abouomar.caesar-agency.co.uk',
            'deleteAccountMailto' => 'mailto:'.$contactEmail
                .'?subject='.rawurlencode('Delete my Helwany Abu Omar account')
                .'&body='.rawurlencode(
                    "Please delete my Helwany Abu Omar account and associated personal data.\n\n"
                    ."Registered email:\n"
                    ."Full name:\n"
                    ."Phone:\n"
                ),
        ];
    }
}
