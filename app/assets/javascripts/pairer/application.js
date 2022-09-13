//= require rails-ujs
//= require bootstrap-sprockets

window.init = function(){
  $('form').attr('autocomplete', 'off');

  var alerts = $(".alert:not(.permanent)")
  setTimeout(function(){
    alerts.fadeOut();
  }, 8000);

  $('.is-chosen').chosen({
    width: '220px', 
    search_contains: true,
  });

  $('.chosen-100').chosen({
    width: '100%', 
    search_contains: true,
  });
}

$(function(){
  window.init();
});

function equals(obj1, obj2){
  if((obj1 == null || typeof obj1 != 'object') || (obj2 == null || typeof obj2 != 'object')){
    return obj1 == obj2;
  }

  for(var propName in obj1){
    if(obj1.hasOwnProperty(propName) != obj2.hasOwnProperty(propName)){
      return false;
    }else if(typeof obj1[propName] != typeof obj2[propName]){
      return false;
    }
  }
  for(var propName in obj2){
    var val = obj1[propName];
    var other = obj2[propName];
    if(obj1.hasOwnProperty(propName) != obj2.hasOwnProperty(propName)){
      return false;
    }else if(typeof val != typeof other){
      return false;
    }

    if(!obj1.hasOwnProperty(propName)){
      continue;
    }

    if(!equals(val, other)){
      return false;
    }
  }
  return true;
};
