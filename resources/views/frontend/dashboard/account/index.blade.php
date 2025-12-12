@extends('frontend.dashboard.dashboard-app')

@section('dashboard_contents')
<div id="account-detail" role="tabpanel" aria-labelledby="account-detail-tab">
    <div class="card">
        <div class="card-header p-0">
            <h5>{{ __('Thông tin tài khoản') }}</h5>
        </div>
        <div class="card-body p-0">
            <p>{{ __('Bạn có thể chỉnh sửa thông tin tài khoản ở đây') }}</p>
            <form action="{{ route('profile.update') }}" method="POST" enctype="multipart/form-data">
                @csrf
                @method('PUT')

                <div class="row mt-30">
                    <x-input-image name="avatar" :image="auth('web')->user()->avatar" />

                    <div class="form-group col-md-12 mt-4">
                        <label class="font-weight-bold">{{ __('Họ và tên') }} <span class="text-danger">*</span></label>
                        <input required class="form-control" name="name" type="text"
                            value="{{ old('name', auth('web')->user()->name) }}" />
                        <x-input-error :messages="$errors->get('name')" class="mt-2" />
                    </div>
                    <div class="form-group col-md-12">
                        <label class="font-weight-bold">{{ __('Email') }} <span class="text-danger">*</span></label>
                        <input required class="form-control" name="email" type="email"
                            value="{{ old('email', auth('web')->user()->email) }}" />
                        <x-input-error :messages="$errors->get('email')" class="mt-2" />
                    </div>
                    <div class="col-md-12">
                        <button type="submit" class="btn btn-fill-out submit font-weight-bold" name="submit"
                            value="Submit">{{ __('Lưu thay đổi') }}</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div class="card mt-4">
        <div class="card-header p-0">
            <h5>{{ __('Thay đổi mật khẩu') }}</h5>
        </div>
        <div class="card-body p-0">
            <p>{{ __('Bạn có thể thay đổi mật khẩu ở đây') }}</p>
            <form action="{{ route('password.update') }}" method="POST">
                @csrf
                @method('PUT')

                <div class="row mt-30">
                    <div class="form-group col-md-12">
                        <label class="font-weight-bold">{{ __('Mật khẩu hiện tại') }} <span class="text-danger">*</span></label>
                        <input required class="form-control" name="current_password" type="password" />
                        <x-input-error :messages="$errors->get('current_password')" class="mt-2" />
                    </div>
                    <div class="form-group col-md-12">
                        <label class="font-weight-bold">{{ __('Mật khẩu mới') }} <span class="text-danger">*</span></label>
                        <input required class="form-control" name="password" type="password" />
                        <x-input-error :messages="$errors->get('password')" class="mt-2" />
                    </div>
                    <div class="form-group col-md-12">
                        <label class="font-weight-bold">{{ __('Xác nhận mật khẩu') }} <span class="text-danger">*</span></label>
                        <input required class="form-control" name="password_confirmation" type="password" />
                        <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
                    </div>
                    <div class="col-md-12">
                        <button type="submit" class="btn btn-fill-out submit font-weight-bold" name="submit"
                            value="Submit">{{ __('Đổi mật khẩu') }}</button>
                    </div>
                </div>
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