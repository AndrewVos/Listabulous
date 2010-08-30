$(document).ready(function() {
    initializeLogo();
});

function initializeLogo() {
    var logoImage = $("div#logo a img");
    var extension = ".png";
    var extensionWithHover = "hover.png";

    var preloader = new Image();
    preloader.src = logoImage.attr("src").replace(extension, extensionWithHover);

    logoImage.hover(function() {
        $(this).attr("src", $(this).attr("src").replace(extension, extensionWithHover));
    }, function() {
        $(this).attr("src", $(this).attr("src").replace(extensionWithHover, extension));
    });
}