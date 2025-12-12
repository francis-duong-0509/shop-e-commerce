<?php

namespace App\Services;

class AlertService
{
    public static function created($message = null)
    {
        notyf()->success($message ? $message : __('Tạo thành công'));
    }

    public static function updated($message = null)
    {
        notyf()->success($message ? $message : __('Cập nhật thành công'));
    }

    public static function deleted($message = null)
    {
        notyf()->success($message ? $message : __('Xóa thành công'));
    }
}