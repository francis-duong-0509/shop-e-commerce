@props(['name', 'image'])

<div style="background-image: url({{ asset($image) }}); background-size: cover; background-position: center;" {{ $attributes->merge(['id' => 'image-preview', 'class' => 'ms-2 mb-3']) }}>
    <label for="image-upload" id="image-label">{{ __('Chọn ảnh đại diện') }}</label>
    <input type="file" name="{{ $name }}" id="image-upload" />
</div>