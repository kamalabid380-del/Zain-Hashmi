// Zain Hashmi - Theme JS
document.addEventListener('DOMContentLoaded', function() {
  console.log('Zain Hashmi Theme Loaded');
  const cartForms = document.querySelectorAll('form[action="/cart/add"]');
  cartForms.forEach(function(form) {
    form.addEventListener('submit', function(e) {
      console.log('Product added to cart');
    });
  });
  const menuToggle = document.querySelector('.menu-toggle');
  const headerMenu = document.querySelector('.header-menu');
  if (menuToggle && headerMenu) {
    menuToggle.addEventListener('click', function() {
      headerMenu.classList.toggle('active');
    });
  }
});
