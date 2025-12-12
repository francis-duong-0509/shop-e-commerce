@extends('frontend.layouts.app')

@section('contents')
    <!--Start hero slider-->
    @include('frontend.home.sections.hero-section')
    <!--End hero slider-->


    <!--Start category slider-->
    @include('frontend.home.sections.category-section')
    <!--End category slider-->

    <!--Start banners-->
    @include('frontend.home.sections.banner-section')
    <!--End banners-->

    <!--Products Tabs Start-->
    @include('frontend.home.sections.products-tab-section')
    <!--Products Tabs End-->


    <!--Start 4 banners-->
    @include('frontend.home.sections.banner-section-two')
    <!--End 4 banners-->

    <!--Start Best Sales-->
    @include('frontend.home.sections.flash-sale-section')
    <!--End Best Sales-->


    <!-- Start new arrival -->
    @include('frontend.home.sections.new-arrival-section')
    <!-- End new arrival -->

    <!-- Start CTA section-->
    <section class="wsus__ctg mt-40">
        <div class="container">
            <a href="#" class="wsus__ctg_area">
                <img src="assets/imgs/cta_bg.png" alt="cta" class="img-fluid w-100" />
            </a>
        </div>
    </section>
    <!-- End CTA section-->

    <!-- Start special products -->
    @include('frontend.home.sections.special-products-section')
    <!-- End special products -->

    <!--Start 4 columns products-->
    @include('frontend.home.sections.four-col-products-section')
    <!--End 4 columns products-->
@endsection
