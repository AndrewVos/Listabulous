(function ($) {
    jQuery.fn.watermark = function (watermarkText, watermarkStyle) {
        return this.each(function () {
            var textBox = $(this);

            if (textBox.val() == "") {
                textBox.val(watermarkText);

                if (watermarkStyle) {
                    textBox.addClass(watermarkStyle);
                }
            }

            textBox.focus(function () {
                if (textBox.val() == watermarkText) {
                    textBox.val("");
                    if (watermarkStyle) {
                        textBox.removeClass(watermarkStyle);
                    }
                }
            });

            textBox.blur(function () {
                if (textBox.val() == "") {
                    textBox.val(watermarkText);
                    if (watermarkStyle) {
                        textBox.addClass(watermarkStyle);
                    }
                }
            });
        });
    };
})(jQuery);