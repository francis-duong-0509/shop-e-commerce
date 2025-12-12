@extends('frontend.layouts.app')

@section('contents')
<main class="main pages">
    <x-frontend.breadcrumb :items="[
        ['label' => __('Trang chủ'), 'url' => '/'],
        ['label' => __('Đăng nhập')]
    ]" />

    <div class="page-content pt-150 pb-135">
        <div class="container">
            <div class="row">
                <div class="col-xl-8 col-lg-10 col-md-12 m-auto">
                    <div class="row">
                        <div class="col-lg-6 pr-30 d-none d-lg-block">
                            <img class="border-radius-15" src="{{ asset('assets/frontend/dist/imgs/page/login-1.png') }}" alt="" />
                        </div>
                        <div class="col-lg-6 col-md-8">
                            <div class="login_wrap widget-taber-content background-white">
                                <div class="padding_eight_all bg-white">
                                    <div class="heading_s1">
                                        <h1 class="mb-5">{{ __('Đăng Nhập') }}</h1>
                                        <p class="mb-30">{{ __('Bạn không có tài khoản?') }} <a href="{{ route('register') }}">{{ __('Đăng ký tại đây') }}</a></p>
                                    </div>

                                    <!-- Session Status -->
                                    <x-auth-session-status class="mb-4" :status="session('status')" />

                                    <form action="{{ route('login') }}" method="POST">
                                        @csrf

                                        <div class="form-group">
                                            <input type="email" name="email" :value="old('email')" placeholder="{{ __('Địa chỉ email') }}" required />
                                            <x-input-error :messages="$errors->get('email')" class="mt-2" />
                                        </div>

                                        <div class="form-group">
                                            <input required type="password" name="password" placeholder="{{ __('Mật khẩu của bạn') }}" />
                                            <x-input-error :messages="$errors->get('password')" class="mt-2" />
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

                                        <div class="login_footer form-group mb-50">
                                            <div class="chek-form">
                                                <div class="custome-checkbox">
                                                    <input class="form-check-input" type="checkbox" name="remember" id="remember_me" value="" />
                                                    <label class="form-check-label" for="remember_me"><span>{{ __('Ghi nhớ tôi') }}</span></label>
                                                </div>
                                            </div>
                                            <a class="text-muted" href="{{ route('password.request') }}">{{ __('Quên mật khẩu?') }}</a>
                                        </div>
                                        <div class="form-group">
                                            <button type="submit" class="btn btn-heading btn-block hover-up" name="login">{{ __('Đăng nhập') }}</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</main>
@endsection
