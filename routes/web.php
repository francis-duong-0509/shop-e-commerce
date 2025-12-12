<?php

use App\Http\Controllers\Frontend\UserDashboardController;
use App\Http\Controllers\Frontend\ProfileController;
use App\Http\Controllers\Frontend\Vendor\VendorDashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('frontend.home.index');
});

// =============================================== USER ROUTES ===============================================
Route::group(['middleware' => ['auth', 'verified']], function () {
    // Dashboard Routes
    Route::get('/dashboard', [UserDashboardController::class, 'index'])->name('dashboard');

    // Profile Routes
    Route::get('/profile', [ProfileController::class,'index'])->name('profile');
    Route::put('/profile', [ProfileController::class, 'profileUpdate'])->name('profile.update');
    Route::put('/profile/password', [ProfileController::class, 'passwordUpdate'])->name('password.update');
});

// =============================================== VENDOR ROUTES ===============================================
Route::group(['prefix' => 'vendor', 'as' => 'vendor.', 'middleware' => ['auth', 'verified']], function () {
    Route::get('/dashboard', [VendorDashboardController::class, 'index'])->name('dashboard');
});


require __DIR__.'/auth.php';