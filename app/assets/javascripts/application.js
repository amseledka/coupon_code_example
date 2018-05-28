//= require jquery.min
//= require jquery.visible
//= require jquery.form-validator
//= require fancybox
//= require inputmask.js
//= require jquery.inputmask.js
//= require materialize.app.js
//= require jquery.form-validator
//= require index.js
//= require product.js
//= require lookbook.js
//= require shop.js
//= require blog.js
//= require cart.js
//= require checkout.js
//= require recent-blog-posts.js

String.prototype.ucfirst = function() {
    return this.charAt(0).toUpperCase() + this.substr(1);
};

function isiPad(){
    return (navigator.platform.indexOf("iPad") != -1);
}

function scrollToId(id) {
    var obj = null;

    if (typeof(id) == 'object') {
        obj = id;
    } else if (typeof(id) == 'string') {
        obj = $('#' + id);
    }
    $("html, body").animate(
        { scrollTop: obj.offset().top - 60 },
        200
    );
}

function getVisible(element) {
    var scrollTop = $(this).scrollTop(),
        scrollBot = scrollTop + $(this).height(),
        elTop = element.offset().top,
        elBottom = elTop + element.outerHeight(),
        visibleTop = elTop < scrollTop ? scrollTop : elTop,
        visibleBottom = elBottom > scrollBot ? scrollBot : elBottom;
    return visibleBottom - visibleTop;
}

function getVisibleItem(items) {
    var visibleItem = null,
        biggestVisibleHeight = 0;

    items.each(function () {
        var currentHeight = getVisible($(this));
        if ($(this).visible(true) && currentHeight > biggestVisibleHeight) {
            biggestVisibleHeight = currentHeight;
            visibleItem = $(this);
        }
    });

    return visibleItem;
}

function setPageNavPosition(pageNav, currentOffset, maxOffset) {
    currentOffset -= pageNav.height();
    if (currentOffset >= maxOffset) {
        pageNav.css('position', 'relative');
    } else {
        pageNav.css('position', 'fixed');
    }
}

$(document).ready(function() {

    $.ajaxSetup({
        headers: {
            'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        }
    });

    // Initialize side navigation
    $("#slide-nav-open").sideNav({
        menuWidth: 300,
        edge: 'left'
    });
    $("#slide-cart-open").sideNav({
        menuWidth: 275,
        edge: 'right'
    });

    // Language switcher in the side nav.
    $('.languages')
        .mouseover(function () {
            $(this).removeClass('closed').addClass('opened');
        })
        .mouseout(function () {
            $(this).removeClass('opened').addClass('closed');
        });

    $.validate({
        showHelpOnFocus : false,
        addSuggestions : false,
        scrollToTopOnError : false
    });
});
