<?php

namespace App\Http\Controllers\Frontend;

use App\Http\Controllers\Controller;
use App\Services\AlertService;
use App\Traits\FileUploadTrait;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    use FileUploadTrait;

    public function index(): View
    {
        return view('frontend.dashboard.account.index');
    }

    public function profileUpdate(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'unique:users,email,' . auth('web')->user()->id],
            'avatar' => ['nullable', 'image', 'max:2048'],
        ], [
            'name.required' => __('Tên là bắt buộc'),
            'email.required' => __('Email là bắt buộc'),
            'email.email' => __('Email không hợp lệ'),
            'email.unique' => __('Email đã tồn tại'),
        ]);


        $user = auth('web')->user();

        if ($request->hasFile('avatar')) {
            $user->avatar = $this->uploadFile($request->file('avatar'), $user->avatar);
        }

        $user->name = $request->name;
        $user->email = $request->email;
        $user->save();

        AlertService::updated();

        return redirect()->back();
    }

    public function passwordUpdate(Request $request): RedirectResponse
    {
        $request->validate([
            'current_password' => ['required', 'string', 'min:8', 'max:50', 'current_password'],
            'password' => ['required', 'string', 'min:8', 'max:50', 'confirmed'],
            'password_confirmation' => ['required', 'string', 'min:8', 'max:50'],
        ], [
            'current_password.required' => __('Mật khẩu hiện tại là bắt buộc'),
            'current_password.current_password' => __('Mật khẩu hiện tại không chính xác'),
            'password.required' => __('Mật khẩu mới là bắt buộc'),
            'password.min' => __('Mật khẩu mới phải có ít nhất 8 ký tự'),
            'password.confirmed' => __('Mật khẩu xác nhận không khớp'),
            'password_confirmation.required' => __('Mật khẩu xác nhận là bắt buộc'),
            'password_confirmation.min' => __('Mật khẩu xác nhận phải có ít nhất 8 ký tự'),
        ]);

        $user = auth('web')->user();
        $user->password = bcrypt($request->password);
        $user->save();

        AlertService::updated();

        return redirect()->back();
    }
}
