(function ($) {

    $.fn.shrinkTo = function (top, left, callback) {
        this.each(function () {
            var element = $(this);

            top = top - element.offset().top;
            left = left - element.offset().left;

            var clonedElement = element.clone();
            $("body").append(clonedElement);

            clonedElement.css({
                "position": "absolute",
                "top": element.offset().top,
                "left": element.offset().left
            });

            clonedElement.animate({ opacity: 0.5, marginLeft: left, marginTop: top, width: 0, height: 0 }, 600, function () {
                clonedElement.remove();
                if ($.isFunction(callback)) {
                    callback.call(this);
                }
            });
        });
    };

})(jQuery);
