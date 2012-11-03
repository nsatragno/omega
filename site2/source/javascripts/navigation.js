function show_login_controls(){
  $('#register_link').show();
  $('#login_link').show();
  $('#logout_link').hide();
  $('#account_link').hide();
}

function show_logout_controls(){
  $('#account_link').show();
  $('#logout_link').show();
  $('#login_link').hide();
  $('#register_link').hide();
}

function show_login_dialog(){
  show_dialog('Login', '#login_dialog');
}

function submit_login_dialog(){
  var user_id = $('#omega_dialog #login_username').attr('value');
  var user_password = $('#omega_dialog #login_password').attr('value');
  var user = new User({ id : user_id, password : user_password });
  hide_dialog();
  login_user(user);
}

function handle_logout_click(){
  logout_user();
  destroy_session();
  show_login_controls();
}

function show_register_dialog(){
  show_dialog('Create Account', '#register_dialog');

  // FIXME make recaptcha public key variable / configurable
  $('#omega_dialog #omega_recaptcha').html('<div id="omega_registration_recaptcha"></div>');
  Recaptcha.create("6LflM9QSAAAAAHsPkhWc7OPrwV4_AYZfnhWh3e3n", "omega_registration_recaptcha",
                   { theme: "red", callback: Recaptcha.focus_response_field});
}

function callback_registration_submitted(user, error){
  if(error){
    show_dialog('Failed to create account', '#registration_failed_dialog', error['message'])
  }else{
    show_dialog('Creating Account', '#registration_submitted_dialog')
  }
}

function submit_register_dialog(){
  var user_id = $('#omega_dialog #register_username').attr('value');
  var user_password = $('#omega_dialog #register_password').attr('value');
  var user_email    = $('#omega_dialog #register_email').attr('value');
  var recaptcha_challenge = Recaptcha.get_challenge();
  var recaptcha_response  = Recaptcha.get_response();
  var user = new User({ id : user_id, password : user_password, email : user_email,
                        recaptcha_challenge : recaptcha_challenge,
                        recaptcha_response : recaptcha_response});

  hide_dialog();
  register_user(user, callback_registration_submitted);
}

function toggle_navigation(result, error){
  if(error){
    show_login_controls();
  }else{
    show_logout_controls();
  }
}

$(document).ready(function(){ 
  $validate_session_callbacks.push(toggle_navigation);
  $login_callbacks.push(toggle_navigation);

  $('#login_link').live('click', function(event){ show_login_dialog(); });
  //$('#omega_dialog input').live('keypress', function(e){ if(e.keyCode == 13) submit_login_dialog(); }); // submit on enter
  $('#login_button').live('click', function(event){ submit_login_dialog(); });

  $('#logout_link').live('click', function(event){ handle_logout_click(); });

  $('#register_link').live('click', function(event){ show_register_dialog(); });
  $('#register_button').live('click', function(event){ submit_register_dialog(); });
});