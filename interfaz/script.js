$(document).ready(function() {

	$('#myTab a').click(function (e) {
	  e.preventDefault()
	  $(this).tab('show')
	});

	$("#schdl").click( function () {
		$(".schdl").show();
		$(this).hide();
	});

	$('#myModalS').on('hidden.bs.modal', function (e) {
	  $(".schdl").hide();
	  $("#schdl").show();
	});

});
