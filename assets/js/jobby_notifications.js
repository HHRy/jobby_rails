/*  Jobby Notifications JavaScript
 *  Ryan Stenhouse - December 2009
 *
 *  Uses JQuery and the Gritter and Timer plugins.
 */

var Notifications = {

  notify: function(params){
    if (!params.title || !params.message) {
      throw 'You need to specify a title and a message for your notification';
    }
    var title = params.title;
    var message = params.message;
    if(!params.image){
      $.gritter.add({
        title: title,
        text:  message
      });
    }else{
      $.gritter.add({
        title: title,
        text:  message,
        image: params.image
      });
    }
  },  

  error: function(params){
    Notifications.notify({
      title: params.title,
      message: params.message,
      image: '/images/min_error.png'
    });
  },

  notice: function(params){
    Notifications.notify({
      title: params.title,
      message: params.message,
      image: '/images/min_notice.png'
    });
  },

  complete: function(params){
    Notifications.notify({
      title: params.title,
      message: params.message,
      image: '/images/min_complete.png'
    });
  },

  working: function(params){
    Notifications.notify({
      title: params.title,
      message: params.message,
      image: '/images/big_spinner.gif'
    });
  }

}

var JobbyNotify = {

 /* Makes an XHR Request to jobs#status and parses the JSON object it gets
  * gets back. Will show an appropriate notification message depending on
  * the response back.
  */  
  notifyStatus: function(params){
    if (!params.jobId) {
      throw 'You need to specify the ID of the JobbyJob you are looking for';
    }
    var jobId = params.jobId;
    $.ajaxSetup({cache: false}); 
    $.ajax({
      url:      '/jobs/status/',
      data:     ({id: jobId}),
      dataType: 'json',
      success:  function(response){
        if(response.jobStatus == 'RUNNING'){
          Notifications.working({title: response.title, message: response.message});          
        }
        else if(response.jobStatus == 'DONE'){
          Notifications.complete({title: response.title, message: response.message});          
        }   
        else if(response.jobStatus == 'ERROR'){
          Notifications.error({title: response.title, message: response.message});          
        }  
        else{
          Notifications.notice({title: response.title, message: response.message});          
        } 
      },
    });    
  }  

}

/*
	Looks for every single link with the class jobsLink, and attached as an
	onclick hook an XHR Request which will notify with the status of the job.
	This is designed to work the the included partial.
*/
function jobbyLinksXHR(){
  $('a.jobsLink').each(function(i,link){
    var oldLink = link.href;
    var jobId = oldLink.split('/')[5];
    link.onclick = function() { JobbyNotify.notifyStatus({ jobId: jobId }) };
    link.href = '#';
  });
}

/*
	Again, for each item we're monitoring in the Jobby Notification area we
	attach a timer which will poll every ten seconds and 
*/
function addCallbackTimer() {
  $('.jobbyListItem').each(function(i, li){
    var jobId = li.title;
    var className = $('a span', li).attr('class');
    if(className != 'ldone' && className != 'lerror'){
      $(document).everyTime('10s','job'+jobId,function (){
        $.ajaxSetup({cache: false});
        $.ajax({
          url:      '/jobs/status',
          data:     ({id: jobId, call: 1}),
          dataType: 'json',
          success: function(response){ processJobResponse(response, li);}
        });
      });
    }
  });
}

function processJobResponse(response, li){
  var jobId = response.jobId;
  var jobStatus = response.jobStatus;

  $('a span', li).removeClass();

  if(jobStatus == 'RUNNING'){
    $('a span', li).addClass('lrunning');  
  }
  else if(jobStatus == 'DONE'){
    Notifications.complete({title: response.title, message: response.message});          
    $(document).stopTime('job'+jobId)
    $('a span', li).addClass('ldone');  
  }   
  else if(jobStatus == 'ERROR'){
    Notifications.error({title: response.title, message: response.message});          
    $(document).stopTime('job'+jobId)
    $('a span', li).addClass('lerror');  
  }  
  else{
    Notifications.notice({title: response.title, message: response.message});          
  }
}

$(document).ready(function(){
  jobbyLinksXHR();
  addCallbackTimer();
});
