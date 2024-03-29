package org.bigbluebutton.view.navigation.pages.userdetails {
	
	import flash.events.MouseEvent;
	import mx.core.FlexGlobals;
	import org.bigbluebutton.model.IConferenceParameters;
	import org.bigbluebutton.model.IUserSession;
	import org.bigbluebutton.model.User;
	import spark.components.Button;
	
	public class UserDetaisView extends UserDetaisViewBase implements IUserDetaisView {
		public function UserDetaisView():void {
		}
		
		protected var _user:User;
		
		protected var _userMe:User;
		
		protected var _conferenceParameters:IConferenceParameters;
		
		public function set conferenceParameters(c:IConferenceParameters):void {
			_conferenceParameters = c;
		}
		
		public function set user(u:User):void {
			_user = u;
			update();
		}
		
		public function set userMe(u:User):void {
			_userMe = u;
			update();
		}
		
		public function get user():User {
			return _user;
		}
		
		public function get userMe():User {
			return _userMe;
		}
		
		public function update():void {
			if (user != null && FlexGlobals.topLevelApplication.mainshell != null && userMe != null) {
				if (_user.me) {
					userNameText.text = _user.name + " " + resourceManager.getString('resources', 'userDetail.you');
				} else {
					userNameText.text = _user.name;
				}
				if (_user.presenter) {
					roleText.text = resourceManager.getString('resources', 'participants.status.presenter');
					if (_user.role == User.MODERATOR) {
						roleText.text += "/" + resourceManager.getString('resources', 'participants.status.moderator');
					}
				} else if (_user.role == User.MODERATOR) {
					roleText.text = resourceManager.getString('resources', 'participants.status.moderator');
				} else {
					roleText.text = "";
				}
				if (_user.status != User.NO_STATUS && _userMe.role == User.MODERATOR) {
					clearStatusButton.includeInLayout = true;
					clearStatusButton.visible = true;
				} else {
					clearStatusButton.includeInLayout = false;
					clearStatusButton.visible = false;
				}
				if (!_user.presenter && _userMe.role == User.MODERATOR) {
					makePresenterButton.includeInLayout = true;
					makePresenterButton.visible = true;
				} else {
					makePresenterButton.includeInLayout = false;
					makePresenterButton.visible = false;
				}
				if (_userMe.role == User.MODERATOR && !_user.me && _conferenceParameters.serverIsMconf) {
					promoteButton.includeInLayout = true;
					promoteButton.visible = true;
					if (_user.role == User.MODERATOR) {
						promoteButton.label = resourceManager.getString('resources', 'userDetail.promoteBtn.demoteText');
					} else {
						promoteButton.label = resourceManager.getString('resources', 'userDetail.promoteBtn.promoteText');
					}
				} else {
					promoteButton.includeInLayout = false;
					promoteButton.visible = false;
				}
				if (!_conferenceParameters.serverIsMconf) {
					clearStatusButton.label = resourceManager.getString('resources', 'profile.settings.handLower');
				}
				cameraIcon.visible = cameraIcon.includeInLayout = _user.hasStream;
				micIcon.visible = micIcon.includeInLayout = (_user.voiceJoined && !_user.muted);
				micOffIcon.visible = micOffIcon.includeInLayout = (_user.voiceJoined && _user.muted);
				noMediaText.visible = noMediaText.includeInLayout = (!_user.voiceJoined && !_user.hasStream);
				//TODO: buttons
				showCameraButton0.includeInLayout = _user.hasStream;
				showCameraButton0.visible = _user.hasStream;
				showPrivateChat0.includeInLayout = !_user.me;
				showPrivateChat0.visible = !_user.me;
			}
		}
		
		public function dispose():void {
		}
		
		public function get showCameraButton():Button {
			return showCameraButton0;
		}
		
		public function get showPrivateChat():Button {
			return showPrivateChat0;
		}
		
		public function get clearStatusButton():Button {
			return clearStatusButton0;
		}
		
		public function get promoteButton():Button {
			return promoteButton0;
		}
		
		public function get makePresenterButton():Button {
			return makePresenterButton0;
		}
	}
}
