@extends('frontend.layouts.app')

@section('contents')
<main class="main pages">
    <x-frontend.breadcrumb :items="[
        ['label' => __('Trang chủ'), 'url' => '/'],
        ['label' => __('Đăng nhập')]
    ]" />

    <div class="page-content pt-150 pb-140">
        <div class="container">
            <div class="row">
                <div class="col-xl-5 col-lg-6 col-md-12 m-auto">
                    <div class="login_wrap widget-taber-content background-white">
                        <div class="padding_eight_all bg-white">
                            <div class="heading_s1 mb-4">
                                <img class="border-radius-15" src="assets/imgs/page/forgot_password.svg" alt="" />
                                <h2 class="mb-15 mt-15">{{ __('Quên Mật Khẩu?') }}</h2>
                                <p>{{ __('Quên mật khẩu? Không vấn đề gì. Chỉ cần cho chúng tôi biết địa chỉ email của bạn và chúng tôi sẽ gửi cho bạn một liên kết đặt lại mật khẩu qua email, cho phép bạn chọn mật khẩu mới.') }}</p>
                            </div>

                            <!-- Session Status -->
                            <x-auth-session-status class="mb-4" :status="session('status')" />

                            <form action="{{ route('password.email') }}" method="POST">
                                @csrf

                                <div class="form-group">
                                    <input type="email" required name="email" placeholder="{{ __('Nhập địa chỉ email') }}" />
                                    <x-input-error :messages="$errors->get('email')" class="mt-2" />
                                </div>

                                {{-- <div class="login_footer form-group">
                                    <div class="chek-form">
                                        <input type="text" required="" name="email" placeholder="Security code *" />
                                    </div>
                                    <span class="security-code">
                                        <b class="text-new">8</b>
                                        <b class="text-hot">6</b>
                                        <b class="text-sale">7</b>
                                        <b class="text-best">5</b>
                                    </span>
                                </div> --}}

                                <div class="form-group">
                                    <button type="submit" class="btn btn-heading btn-block hover-up" name="login">{{ __('Gửi') }}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</main>
@endsection
