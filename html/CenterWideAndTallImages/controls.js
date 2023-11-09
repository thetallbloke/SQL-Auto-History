/*
    This is a helper file to simply allow the sliders to work.
    It is not necessary to use this file for anythis other than to make the sliders work for the exmamples on the page.
*/
$(function () {
    var wSlider = document.getElementById("WidthRange");
    var hSlider = document.getElementById("HeightRange");
    var txtWOutput = document.getElementById("txtWidth");
    var txtHOutput = document.getElementById("txtHeight");

    txtWOutput.value = `${wSlider.value}px`;
    txtHOutput.value = `${hSlider.value}px`;

    // Update the current slider value (each time you drag the slider handle)
    wSlider.oninput = function () {
        txtWOutput.value = `${this.value}px`;
        $('.res').css('width', this.value);
    }

    hSlider.oninput = function () {
        txtWOutput.value = `${this.value}px`;
        $('.res').css('height', this.value);
    }
})