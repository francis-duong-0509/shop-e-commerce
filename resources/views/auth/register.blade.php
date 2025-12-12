@extends('frontend.layouts.app')

@section('contents')
<main class="main pages">
    <x-frontend.breadcrumb :items="[
        ['label' => __('Trang chủ'), 'url' => '/'],
        ['label' => __('Đăng ký')]
    ]" />

    <div class="page-content pt-150 pb-140">
        <div class="container">
            <div class="row">
                <div class="col-xxl-8 col-xl-10 col-lg-12 col-md-9 m-auto">
                    <div class="row align-items-center">
                        <div class="col-lg-6">
                            <div class="login_wrap widget-taber-content background-white">
                                <div class="padding_eight_all bg-white">
                                    <div class="heading_s1">
                                        <h2 class="mb-5">{{ __('Đăng Ký') }}</h2>
                                        <p class="mb-30">{{ __('Bạn đã có tài khoản?') }}<a href="{{ route('login') }}">{{ __('Đăng nhập') }}</a></p>
                                    </div>
                                    <form action="{{ route('register') }}" method="POST">
                                        @csrf

                                        <div class="form-group">
                                            <input type="text" required name="name" value="{{ old('name') }}" placeholder="{{ __('Họ và tên') }}" />
                                            <x-input-error :messages="$errors->get('name')" class="mt-2" />
                                        </div>

                                        <div class="form-group">
                                            <input type="email" required name="email" value="{{ old('email') }}" placeholder="{{ __('Địa chỉ email') }}" />
                                            <x-input-error :messages="$errors->get('email')" class="mt-2" />
                                        </div>

                                        <div class="form-group">
                                            <input required type="password" name="password" placeholder="{{ __('Nhập mật khẩu') }}" />
                                            <x-input-error :messages="$errors->get('password')" class="mt-2" />
                                        </div>

                                        <div class="form-group">
                                            <input required type="password" name="password_confirmation" placeholder="{{ __('Xác nhận lại mật khẩu') }}" />
                                            <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
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

                                        <div class="payment_option mb-30">
                                            <div class="custome-radio">
                                                <input class="form-check-input" name="user_type" value="user" required type="radio" id="exampleRadios3" checked />
                                                <label class="form-check-label" for="exampleRadios3">{{ __('Tôi là khách hàng') }}</label>
                                            </div>
                                            <div class="custome-radio">
                                                <input class="form-check-input" name="user_type" value="vendor" required type="radio" id="exampleRadios4" />
                                                <label class="form-check-label" for="exampleRadios4">{{ __('Tôi là người bán') }}</label>
                                            </div>
                                        </div>
                                        <div class="form-group mb-0">
                                            <button type="submit" class="btn btn-fill-out btn-block hover-up font-weight-bold">{{ __('Đăng ký') }}</button>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                        <div class="col-lg-6">
                            <div class="card-login">
                                <a href="#" class="social-login google-login">
                                    <img src="{{ asset('assets/frontend/dist/imgs/theme/icons/logo-google.svg') }}" alt="" />
                                    <span>{{ __('Đăng nhập với Google') }}</span>
                                </a>
                                <a href="#" class="social-login facebook-login">
                                    <img src="{{ asset('assets/frontend/dist/imgs/theme/icons/logo-facebook.svg') }}" alt="" />
                                    <span>{{ __('Đăng nhập với Facebook') }}</span>
                                </a>                                
                                <a href="#" class="social-login apple-login">
                                    <img src="{{ asset('assets/frontend/dist/imgs/theme/icons/logo-apple.svg') }}" alt="" />
                                    <span>{{ __('Đăng nhập với Apple') }}</span>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</main>
@endsection
