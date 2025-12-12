<?php

namespace App\Http\Controllers\Frontend\Vendor;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;
use Illuminate\Http\Request;

class VendorDashboardController extends Controller
{
    public function index(): View
    {
        return view('vendor-dashboard.dashboard.index');
    }
}
