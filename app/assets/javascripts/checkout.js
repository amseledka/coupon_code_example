$(window).load(function() {

  if ($('.checkout-container').length) {

    var renderCheckoutCart = function (cart) {
      var cartListContainer = $('#checkout-cart-body'),
        cartTotalHolder = $('#checkout-cart-total');

      var total = cart.total,
        items = cart.items;

      var list = '';
      for (var i = 0; i < cart.amount; i++) {
        list +=
          '<div class="row">' +
            '<div class="col m1 valign-wrapper">' +
              '<a href="' + items[i]['url'] + '">' +
                '<img src="' + items[i]['image'] + '" class="image valign">' +
              '</a>' +
            '</div>' +
            '<div class="col m4 valign-wrapper name-wrapper">' +
              '<span class="valign name">' +
                items[i]['name'] + ' ' + items[i]['color'] +
              '</span>' +
            '</div>' +
            '<div class="col m1 valign-wrapper code-wrapper">' +
              '<span class="valign code">' +
                items[i]['code'] +
              '<span>' +
            '</div>' +
            '<div class="col m2 valign-wrapper price-wrapper">' +
              '<span class="valign new price">' +
                '<sup>' + currency + '</sup>' +
                (items[i].discount_price === null ? items[i].price : items[i].discount_price) +
              '</span>' +
              (items[i].discount_price !== null ?
                '<span class="old"><sup>' + items[i].price + '</sup></span>' : '') +
              '<button ' +
                'class="remove remove-from-checkout-cart" ' +
                'data-product-id="' + cart.items[i]['id'] + '">' +
                  '<i class="fa fa-times"></i>' +
              '</button>' +
            '</div>' +
          '</div>';
      }

      // Render list.
      cartListContainer.html(list);
      // Render total
      rerenderCartTotal(includeCourierFee);
    };

    // Remove item from cart
    $(document).on('click', '.remove-from-checkout-cart', function () {
      var productId = $(this).attr('data-product-id');

      $.ajax({
        type: 'DELETE',
        url: '/cart',
        dataType: 'json',
        data: {
          product_id: productId,
          locale: locale
        }
      }).done(function (data) {
        if (data['status'] == 'success') {
          cart = data.cart;
          renderCheckoutCart(data.cart);

          // Defined in cart.js
          renderCart(data.cart);
        }
      }).fail(function () {
        alert('Failed!');
      });

      return false;
    });

    // Promo code
    $couponForm = $('#coupon-form');
    $couponFormInput = $couponForm.find('input[name="coupon"]');

    $couponFormInput.focus(function() {
      if (!$couponForm.find('.form-error').hasClass('display-none')) {
        $couponForm.find('.form-error').addClass('display-none');
        $couponFormInput.removeClass('has-error');
      }
    });

    $couponFormInput.inputmask({"regex": "^GUD-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}$"});

    // Apply promo code
    $couponForm.find('[type="submit"]').click(function() {
      $.ajax({
        type: 'PUT',
        url: $couponForm.attr('action'),
        dataType: 'json',
        data: $couponForm.serialize() + "&locale=" + locale
      }).done(function (response) {
          if (response['status'] == 'success') {
            cart = response.cart;
            rerenderCartTotal(includeCourierFee);
            $('#form_coupon_input').val(cart.coupon);
            $('.section-promo-code-applied .title strong').text(cart.coupon);
            $('.section-promo-code-applied').removeClass('hide');
            $('#coupon-form').addClass('hide');
          } else if (response['status'] == 'fail') {
            $couponForm.find('.form-error').removeClass('display-none');
            $couponFormInput.addClass('has-error');
          }
        }).fail(function () {
          alert('Failed!');
        });

      return false;
    });

    // Remove Promo code
    $(document).on('click', '.remove-coupon-link', function () {
      $.ajax({
        type: 'PUT',
        url: '/remove_coupon',
        data: {
          locale: locale
        },
        dataType: 'json'
      }).done(function (response) {
          if (response['status'] == 'success') {
            cart = response.cart;
            rerenderCartTotal(includeCourierFee);
            $('.section-promo-code-applied').addClass('hide');
            $('#coupon-form').removeClass('hide');
            $('#form_coupon_input').val(cart.coupon);
          }
        }).fail(function () {
          alert('Failed!');
        });

      return false;
    });


    var shipmentWorldwideSection = $('#section-shipment-ww'),
      paymentWorldwideSection = $('#section-payment-ww');

    var shipmentUkraineSection = $('#section-shipment-u'),
      paymentUkraineSection = $('#section-payment-u'),
      shipmentUCourierSection = $('#section-shipment-u-courier'),
      shipmentUNovaPoshtaSection = $('#section-shipment-u-nova-poshta');

    var courierFeeSection = $('#section-courier-fee');

    var ukrainianSections = [
      shipmentUkraineSection,      // Shipment switcher. Courier or Nova Poshta.
      paymentUkraineSection,       // Payment switcher.
      shipmentUCourierSection,     // Inputs for delivery by courier.
      shipmentUNovaPoshtaSection,  // Inputs for delivery by Nova Poshta.
      courierFeeSection            // 'Courier fee' section in the right part.
    ];

    var worldwideSections = [
      shipmentWorldwideSection, // Inputs for delivery.
      paymentWorldwideSection   // Payment switcher. PayPal or 2Checkout.
    ];

    // Add 'disabled' class to each section. Add 'disabled' attr to all inputs.
    var disableSections = function(sections) {
      for (var i = 0; i < sections.length; i++) {
        sections[i].addClass('disabled');
        sections[i].find('input').each(function() {
          $(this).attr('disabled', true);
        });
      }
    };
    // Remove 'disabled' class from each section. Remove 'disabled' attr from all inputs.
    var activateSections = function(sections) {
      for (var i = 0; i < sections.length; i++) {
        sections[i].removeClass('disabled');
        sections[i].find('input').each(function() {
          $(this).removeAttr('disabled');
        });
      }
    };

    var rerenderCartTotal = function(withCourierFee) {
      includeCourierFee = withCourierFee;

      $('#checkout-cart-total').html(
        '<span class="price">' +
          '<sup>' + currency + '</sup>' +
          (withCourierFee ? (cart.total + courierFee) : cart.total) +
        '</span>'
      );
    };

    $('#section-shipment').find('input[type="radio"]').each(function() {
      $(this).click(function() {
        // Hide courier section on right part.
        disableSections([courierFeeSection]);
        rerenderCartTotal(false);
        switch ($(this).attr('value')) {
          case 'ukraine':
            // Hide worldwide all sections
            disableSections(worldwideSections);
            // Show Ukrainian shipment.
            activateSections([shipmentUkraineSection, paymentUkraineSection]);
            shipmentUkraineSection.find('input[value="nova-poshta"]').click();
            break;
          case 'worldwide':
            // Hide Ukrainian sections.
            disableSections(ukrainianSections);
            // Show all worldwide sections.
            activateSections(worldwideSections);
            break;
        }
      });
    });

    shipmentUkraineSection.find('input[type="radio"]').each(function() {
      $(this).click(function() {
        switch ($(this).attr('value')) {
          case 'courier':
            disableSections([shipmentUNovaPoshtaSection]);
            activateSections([shipmentUCourierSection, paymentUkraineSection, courierFeeSection]);
            rerenderCartTotal(true);
            paymentUkraineSection
              .find('input[value="cod"]').attr('disabled', true)
              .closest('.column').addClass('disabled');
            paymentUkraineSection
              .find('input[value="cash"]').attr('disabled', false)
              .closest('.column').removeClass('disabled');
            break;
          case 'nova-poshta':
            disableSections([shipmentUCourierSection, courierFeeSection]);
            rerenderCartTotal(false);
            activateSections([shipmentUNovaPoshtaSection]);
            paymentUkraineSection
              .find('input[value="cod"]').attr('disabled', false)
              .closest('.column').removeClass('disabled');
            paymentUkraineSection
              .find('input[value="cash"]').attr('disabled', true)
              .closest('.column').addClass('disabled');
            break;
        }
      });
    });

    var checkoutForm = $('#checkout-form'),
      paymentForm = $('#payment-form'),
      submitButton = checkoutForm.find('[type="submit"]');

    submitButton.click(function() {
      // Clean up payment form container.
      paymentForm.html('');

      if (checkoutForm.isValid()) {
        console.log('Form valid');
        submitButton.addClass('processing').attr('disabled', true);

        // Get payment form
        $.ajax({
          type: 'POST',
          url: checkoutForm.attr('action'),
          dataType: 'json',
          data: checkoutForm.serialize()
        }).done(function (response) {
          if (response['status'] == 'success') {
            if (response['data']['form']) {
              paymentForm.html(response['data']['form']);
              paymentForm.find('form').submit();
            } else if (response['data']['redirect_to']) {
              window.location.href = response['data']['redirect_to'];
            }
          }
        }).fail(function () {
          submitButton.removeClass('processing').attr('disabled', false);
          alert('Failed!');
        });

      } else {
        console.log('Form invalid');
      }
      return false;
    });
  }

});
