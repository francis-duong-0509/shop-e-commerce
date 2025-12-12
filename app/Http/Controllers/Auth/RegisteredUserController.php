<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Illuminate\View\View;

class RegisteredUserController extends Controller
{
    /**
     * Display the registration view.
     */
    public function create(): View
    {
        return view('auth.register');
    }

    /**
     * Handle an incoming registration request.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'lowercase', 'email', 'max:255', 'unique:'.User::class],
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
            'user_type' => ['required', 'in:user,vendor'],
        ], [
            'name.required' => __('Vui lòng nhập tên'),
            'email.required' => __('Vui lòng nhập email'),
            'email.email' => __('Vui lòng nhập email hợp lệ'),
            'email.unique' => __('Email đã tồn tại'),
            'password.required' => __('Vui lòng nhập mật khẩu'),
            'password.confirmed' => __('Mật khẩu không khớp'),
            'user_type.required' => __('Vui lòng chọn loại người dùng'),
            'user_type.in' => __('Loại người dùng không hợp lệ'),
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'user_type' => $request->user_type,
            'password' => Hash::make($request->password),
        ]);

        event(new Registered($user));

        Auth::login($user);

        if (Auth::guard('web')->user()->user_type == 'vendor') {
            return redirect(route('vendor.dashboard', absolute: false));
        }

        return redirect(route('dashboard', absolute: false));
    }
}
