<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\AlertService;
use App\Traits\FileUploadTrait;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ProfileController extends Controller
{
    use FileUploadTrait;

    public function index(): View
    {
        return view('admin.profile.index');
    }

    public function profileUpdate(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . Auth::guard('admin')->user()->id,
            'avatar' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ], [
            'name.required' => __('Tên là bắt buộc'),
            'email.required' => __('Email là bắt buộc'),
            'email.email' => __('Email không hợp lệ'),
            'email.unique' => __('Email đã tồn tại'),
        ]);

        $admin = Auth::guard('admin')->user();

        if ($request->hasFile('avatar')) {
            $admin->avatar = $this->uploadFile($request->file('avatar'), $admin->avatar);
        }

        $admin->name = $request->name;
        $admin->email = $request->email;

        $admin->save();

        AlertService::updated();

        return redirect()->back();
    }

    public function passwordUpdate(Request $request): RedirectResponse
    {
        $request->validate([
            'current_password' => 'required|string|min:8|max:50|current_password',
            'password' => 'required|string|min:8|max:50|confirmed',
            'password_confirmation' => 'required|string|min:8|max:50',
        ], [
            'current_password.required' => __('Mật khẩu hiện tại là bắt buộc'),
            'current_password.current_password' => __('Mật khẩu hiện tại không chính xác'),
            'password.required' => __('Mật khẩu mới là bắt buộc'),
            'password.min' => __('Mật khẩu mới phải có ít nhất 8 ký tự'),
            'password.confirmed' => __('Mật khẩu xác nhận không khớp'),
            'password_confirmation.required' => __('Mật khẩu xác nhận là bắt buộc'),
            'password_confirmation.min' => __('Mật khẩu xác nhận phải có ít nhất 8 ký tự'),
        ]);

        $admin = Auth::guard('admin')->user();
        $admin->password = bcrypt($request->password);

        $admin->save();

        AlertService::updated();

        return redirect()->back();
    }
}
