// random numbers that look like GUIDs - http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
function S4()   { return (((1+Math.random())*0x10000)|0).toString(16).substring(1); }
function guid() { return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()); }
var upload_photo_uuid = undefined;
var upload_voice_uuid = undefined;
var upload_video_uuid = undefined;

function getFileExtension(filename){
  var ext = /^.+\.([^.]+)$/.exec(filename);
  return ext == null ? "" : ext[1];
}
function isImage(){
	ext= getFileExtension($('#photofile').val());
	ext = ext.toLowerCase();
	if(ext=='jpg'||ext=='gif'||ext=='jpeg'||ext=='png')
		return true;
	else{
		$('#PictureError').css({display: 'inline'});
		alert('please, upload only image file');
		return false;
	}
		
}
function update_progress() {
  var uri = '/photoUploadProgress/'+upload_photo_uuid;
  $.getJSON(uri, function(data) {
    progress = data['progress'];
	link = data['link'];
	error = data['error'];
    if (link) {
      if (link=='none') {
		
      }else {
		$('#hiddenphotoId').val(link);
		$('#waitingUploadPicture').css({display: 'none'});
		$('#PictureCorrect').css({display: 'inline'});
      }
    }
	if(error)
		if(error!='none'){
			$('#PictureError').css({display: 'inline'});
			$('#waitingUploadPicture').css({display: 'none'});
		}
    if (link=='none'&& error=='none') {
      setTimeout("update_progress()", 400);	  
    }
  })
  .error(function() { 
		$('#PictureError').css({display: 'inline'});
		$('#waitingUploadPicture').css({display: 'none'});
	});
}
function uploadVoice(){
	upload_voice_uuid = guid();
	$('#CorrectVoice').css({display: 'none'});
	$('#ErrorVoice').css({display: 'none'});
	$('#waitingUploadVoice').css({display: 'inline'});
		 
	$('#uploadVoiceForm').attr('target', 'postframe');		 
	$('#uploadVoiceForm').attr('action', '/uploadVoice/'+upload_voice_uuid);		 
	$('#uploadVoiceForm').submit();		 
	uploadVoiceStatus();		
}
function uploadVoiceStatus(){
	var uri = '/voiceprocess/'+upload_voice_uuid;
  $.getJSON(uri, function(data) {
    progress = data['progress'];
	status = data['status'];
	error= data['error'];
	link= data['link'];
    if (status) {
      if (status=='done') {
		$('#CorrectVoice').css({display: 'inline'});
		$('#waitingUploadVoice').css({display: 'none'});
		$('#uploadVoiceStatus').css({color:'Green'});
		$('#uploadVoiceStatus').html('Upload Successfully');
		$('#voicelink').val(link);
      } else if (status=='error') {
		$('#ErrorVoice').css({display: 'inline'});
		$('#waitingUploadVoice').css({display: 'none'});
		$('#uploadVoiceStatus').css({color:'Red'});
		$('#uploadVoiceStatus').html(error);
      } else {
		$('#waitingUploadVoice').css({display: 'inline'});
		$('#uploadVoiceStatus').css({color:'Blue'});
		$('#uploadVoiceStatus').html(status);
      }
    }
    if (status!='done'&&status!='error') {
      setTimeout("uploadVoiceStatus()", 400);	  
    }
  })
  .error(function() { 
	$('#ErrorVoice').css({display: 'inline'});
	$('#waitingUploadVoice').css({display: 'none'});
	$('#uploadVoiceStatus').css({color:'Red'});
	$('#uploadVoiceStatus').html('Error');
  });
}
function authenYoutube(){
	upload_video_uuid = guid();
	$('#CorrectVideo').css({display: 'none'});
	$('#ErrorVideo').css({display: 'none'});
	$('#waitingUploadVideo').css({display: 'inline'});
	uri = '/youtubeauthen/'+upload_video_uuid;
    $.post(
		uri, 
		{'username': $('#youtubeUser').val(),'password': $('#youtubePassword').val()}, 
		function(key){
			if(key!='error'){
				uploadYoutube(upload_video_uuid,key);
			}
		}
	);
	uploadYoutubeStatus();
}
function uploadYoutube(upload_video_uuid,key){
	var file = $("#videoFile").val();

    if (file != '') {
		$('#youtubekey').val(key);
		$('#uploadVideoForm').attr('target', 'postframe');
		$('#uploadVideoForm').attr('action', '/youtubeupload/'+upload_video_uuid);
		$('#uploadVideoForm').submit();
	}else{
		alert('please, browse a video file');
	}
}
function uploadYoutubeStatus(){
	var uri = '/youtubeprocess/'+upload_video_uuid;
  $.getJSON(uri, function(data) {
    progress = data['progress'];
	status = data['status'];
	error= data['error'];
	link= data['link'];
    if (status) {
      if (status=='done') {
		$('#CorrectVideo').css({display: 'inline'});
		$('#waitingUploadVideo').css({display: 'none'});
		$('#uploadVideoStatus').css({color:'Green'});
		$('#uploadVideoStatus').html('Upload Successfully');
		$('#youtubelink').val(link);
      } else if (status=='error') {
		$('#ErrorVideo').css({display: 'inline'});
		$('#waitingUploadVideo').css({display: 'none'});
		$('#uploadVideoStatus').css({color:'Red'});
		$('#uploadVideoStatus').html(error);
      } else {
		$('#waitingUploadVideo').css({display: 'inline'});
		$('#uploadVideoStatus').css({color:'Blue'});
		$('#uploadVideoStatus').html(status);
      }
    }
    if (status!='done'&&status!='error') {
      setTimeout("uploadYoutubeStatus()", 400);	  
    }
  })
  .error(function() { 
	$('#ErrorVideo').css({display: 'inline'});
	$('#waitingUploadVideo').css({display: 'none'});
	$('#uploadVideoStatus').css({color:'Red'});
	$('#uploadVideoStatus').html('Error');
  });
}
function uploadPhoto(e){
	$('#PictureCorrect').css({display: 'none'});
		$('#PictureError').css({display: 'none'});
		if(isImage()){
			$('#waitingUploadPicture').css({display: 'inline'});
			var file = $("photofile").val();
			if (file != ''){
			  // ok.
			  // TODO: disable submit button.
			  upload_photo_uuid = guid();
			 $('#uploadPictureForm').attr('target', 'postframe');
			 $('#uploadPictureForm').attr('action', '/uploadphoto/'+upload_photo_uuid);
			 $('#uploadPictureForm').submit();
				update_progress();
			}
		}
}
function formValidate(e){
	$('#errorMessage').html('');
	fields = {'title':$('#title').val(),
			'itemDescription':$('#itemDescription').val(),
			'price':$('#price').val(),
			'email':$('#email').val(),
			'neighborhood':$('#address').val(),
			'city':$('#city').val(),
			'state':$('#state').val(),
			'country':$('#country').val()
			}
	uri = '/validateForm';
    $.post(
		uri, 
		fields, 
		function(data){
			if(data==''){
				$('#postPhoto').click();
			}else{
				$('#postPhoto').click();
				$('#errorMessage').css('color','red');
				$('#errorMessage').html('Please, check following fields: '+data);
			}	
		}
	);
}
function checkPhoto(e){
		$('#postVideo').click();	
}
function checkVideo(e){
		$('#postVoice').click();	
}
function checkVoice(e){
		$('#postVoice').colorbox.close();
			
}

$(document).ready(function() {
	//$("#photoFiles").kendoUpload();
	$('#postitem').colorbox({inline:true, width:"50%"});
	$('#postPhoto').colorbox({inline:true, width:"40%", height:"60%"});
	$('#postVideo').colorbox({inline:true, width:"40%"});
	$('#postVoice').colorbox({inline:true,
							  width:"40%",
							  onClosed:function(){
											$('#mainForm').submit();
										}
							  });
	$('#submit').click(function(e){
		
	});
	
	$('#detailNext').click(function(e){
		formValidate(e);
	});
	$('#photoNext').click(function(e){
		checkPhoto(e);
	});
	$('#videoNext').click(function(e){
		checkVideo(e);
	});
	$('#voiceNext').click(function(e){
		checkVoice(e);
	});
	
	$('#submit').click(function(e){
		$('#mainform').submit();
	});
	
    // $('#uploadPhoto').click(function(e) {
		// uploadPhoto(e);
	// });
	
	// $('#uploadVideo').click(function(e){
		// var file = $("#videoFile").val();

		// if (file != '') {
			// authenYoutube();
		// }else{
			// alert('please, browse a video file');
		// }
		
	// });
	// $('#uploadVoice').click(function(e){
		// var file = $("#voiceFile").val();
		// if (file != '') {
			// uploadVoice();
		// }else{
			// alert('please, browse a voice file');
		// }
		
	// });

	
});

 


