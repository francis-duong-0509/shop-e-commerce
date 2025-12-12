@extends('admin.layouts.app')

@section('contents')
<div class="container-xl">
    <div class="card">
        <div class="card-header">
            <h3 class="card-title">{{ __('Cập nhật thông tin') }}</h3>
        </div>
        <div class="card-body">
            <form action="{{ route('admin.profile.update') }}" method="POST" enctype="multipart/form-data">
                @csrf
                @method('PUT')

                <div class="row">
                    <div class="col-md-3">
                        <div class="mb-3">
                            <x-input-image name="avatar" :image="auth('admin')->user()->avatar" />
                        </div>
                    </div>

                    <div class="col-md-9">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label" required>{{ __('Họ và tên') }} <span
                                        class="text-danger">*</span></label>
                                <input type="text" name="name" class="form-control"
                                    value="{{ old('name', Auth::guard('admin')->user()->name) }}">
                                <x-input-error :messages="$errors->get('name')" class="mt-2" />
                            </div>
                        </div>

                        <div class="col-md-6">
                            <div class="mb-3">
                                <label class="form-label" required>{{ __('Địa chỉ email') }} <span
                                        class="text-danger">*</span></label>
                                <input type="email" name="email" class="form-control"
                                    value="{{ old('email', Auth::guard('admin')->user()->email) }}">
                                <x-input-error :messages="$errors->get('email')" class="mt-2" />
                            </div>
                        </div>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">{{ __('Lưu thay đổi') }}</button>
            </form>
        </div>
    </div>

    <div class="card mt-5">
        <div class="card-header">
            <h3 class="card-title">{{ __('Thay đổi mật khẩu') }}</h3>
        </div>
        <div class="card-body">
            <form action="{{ route('admin.password.update') }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row">
                    <div class="col-md-4">
                        <div class="mb-3">
                            <label class="form-label" required>{{ __('Mật khẩu hiện tại') }} <span
                                    class="text-danger">*</span></label>
                            <input type="password" name="current_password" class="form-control">
                            <x-input-error :messages="$errors->get('current_password')" class="mt-2" />
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="mb-3">
                            <label class="form-label" required>{{ __('Mật khẩu mới') }} <span
                                    class="text-danger">*</span></label>
                            <input type="password" name="password" class="form-control">
                            <x-input-error :messages="$errors->get('password')" class="mt-2" />
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="mb-3">
                            <label class="form-label" required>{{ __('Xác nhận mật khẩu mới') }} <span
                                    class="text-danger">*</span></label>
                            <input type="password" name="password_confirmation" class="form-control">
                            <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
                        </div>
                    </div>
                </div>
                <button type="submit" class="btn btn-primary">{{ __('Lưu thay đổi') }}</button>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script type="text/javascript">
    $(document).ready(function() {
        $.uploadPreview({
            input_field: "#image-upload",
            preview_box: "#image-preview",
            label_field: "#image-label",
            label_default: "{{ __('Chọn ảnh đại diện') }}",
            label_selected: "{{ __('Thay đổi ảnh đại diện') }}",
            no_label: false
        });
    });
</script>
@endpush