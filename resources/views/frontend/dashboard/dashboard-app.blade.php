@extends('frontend.layouts.app')

@section('contents')
<main class="main pages">
    <x-frontend.breadcrumb :items="[
        ['label' => __('Trang chủ'), 'url' => '/'],
        ['label' => __('Bảng điều khiển')]
    ]" />

    <div class="page-content pt-70 pb-60">
        <div class="container">
            <div class="row">
                <div class="col-12">
                    <div class="row">
                        <div class="col-md-3">
                            <div class="dashboard-menu">
                                <ul class="nav flex-column" role="tablist">
                                    <li class="nav-item">
                                        <a class="nav-link active" href=""><i class="fi-rs-settings-sliders mr-10"></i>{{ __('Bảng điều khiển') }}</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link"href=""><i class="fi-rs-shopping-bag mr-10"></i>{{ __('Đơn hàng') }}</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href=""><i class="fi-rs-shopping-cart-check mr-10"></i>{{ __('Theo dõi đơn hàng') }}</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href=""><i class="fi-rs-marker mr-10"></i>{{ __('Địa chỉ') }}</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href="{{ route('profile') }}"><i class="fi-rs-user mr-10"></i>{{ __('Thông tin tài khoản') }}</a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" href=""><i class="fi-rs-heart mr-10"></i>{{ __('Yêu thích') }}</a>
                                    </li>
                                </ul>
                            </div>
                        </div>
                        <div class="col-md-9">
                            <div class="tab-content account dashboard-content pl-50">
                                @yield('dashboard_contents')                                                                                                                                                    
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</main>
@endsection
