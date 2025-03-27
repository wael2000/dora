var currentPos;
//var startPosLat = 25.1107009;
//var startPosLong = 55.1915089; 

var startPosLat = 52.346998
var startPosLong = 5.147501

//var startPosLat = 25.1047627;
//var startPosLong = 55.1686255;

var distance;

  window.onload = function() {
    if (navigator.geolocation) {      
      navigator.geolocation.watchPosition(function(position) {   
        currentPos = position;
        distance = calculateDistance(startPosLat, startPosLong,position.coords.latitude, position.coords.longitude)
        refreshActions();
      });
    }
  };

  function refreshActions(){
    if(distance <= 1){
        $("#message").text("Yes, You are close to office")
        $(".book").show();
    }else if(distance > 1){
        $("#message").text("No, You still away from office")
        $(".book").hide();
    }
  }

  function calculateDistance(lat1, lon1, lat2, lon2) {
    var R = 6371; // km
    var dLat = (lat2-lat1).toRad();
    var dLon = (lon2-lon1).toRad();
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1.toRad()) * Math.cos(lat2.toRad()) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    var d = R * c;
    return d;
  }
  Number.prototype.toRad = function() {
    return this * Math.PI / 180;
  }