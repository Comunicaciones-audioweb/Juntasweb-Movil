package org.bigbluebutton.view.navigation.pages.camerasettings {
	
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.CameraPosition;
	import flash.media.Video;
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.events.IndexChangedEvent;
	import mx.events.ItemClickEvent;
	import mx.resources.ResourceManager;
	import org.bigbluebutton.command.CameraQualitySignal;
	import org.bigbluebutton.command.ShareCameraSignal;
	import org.bigbluebutton.core.ISaveData;
	import org.bigbluebutton.core.VideoConnection;
	import org.bigbluebutton.core.VideoProfile;
	import org.bigbluebutton.model.IConferenceParameters;
	import org.bigbluebutton.model.IUserSession;
	import org.bigbluebutton.model.IUserUISession;
	import org.bigbluebutton.model.User;
	import org.bigbluebutton.model.UserList;
	import org.bigbluebutton.model.UserSession;
	import org.bigbluebutton.view.ui.SwapCameraButton;
	import robotlegs.bender.bundles.mvcs.Mediator;
	import spark.events.IndexChangeEvent;
	
	public class CameraSettingsViewMediator extends Mediator {
		
		[Inject]
		public var view:ICameraSettingsView;
		
		[Inject]
		public var userSession:IUserSession;
		
		[Inject]
		public var userUISession:IUserUISession;
		
		[Inject]
		public var shareCameraSignal:ShareCameraSignal;
		
		[Inject]
		public var changeQualitySignal:CameraQualitySignal;
		
		[Inject]
		public var saveData:ISaveData;
		
		[Inject]
		public var conferenceParameters:IConferenceParameters;
		
		protected var dataProvider:ArrayCollection;
		
		override public function initialize():void {
			view.currentState = (conferenceParameters.serverIsMconf) ? "mconf" : "bbb";
			dataProvider = new ArrayCollection();
			view.cameraProfilesList.dataProvider = dataProvider;
			displayCameraProfiles();
			userSession.userList.userChangeSignal.add(userChangeHandler);
			var userMe:User = userSession.userList.me;
			if (Camera.getCamera() == null) {
				view.startCameraButton.label = ResourceManager.getInstance().getString('resources', 'profile.settings.camera.unavailable');
				view.startCameraButton.enabled = false;
			} else {
				view.startCameraButton.label = ResourceManager.getInstance().getString('resources', userMe.hasStream ? 'profile.settings.camera.on' : 'profile.settings.camera.off');
				view.startCameraButton.enabled = true;
			}
			if (Camera.names.length <= 1) {
				setSwapCameraButtonEnable(false);
			} else {
				setSwapCameraButtonEnable(!userMe.hasStream);
				view.swapCameraButton.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				userSession.userList.userChangeSignal.add(userChangeHandler);
			}
			setQualityListEnable(!userSession.userList.me.hasStream);
			setRotateCameraButtonEnable(!userMe.hasStream);
			view.startCameraButton.addEventListener(MouseEvent.CLICK, onShareCameraClick);
			view.rotateCameraButton.addEventListener(MouseEvent.CLICK, onRotateCameraClick);
			view.cameraProfilesList.addEventListener(IndexChangeEvent.CHANGE, onCameraQualitySelected);
			FlexGlobals.topLevelApplication.pageName.text = ResourceManager.getInstance().getString('resources', 'cameraSettings.title');
			displayPreviewCamera();
		}
		
		private function displayCameraProfiles():void {
			var videoProfiles:Array = userSession.videoProfileManager.profiles;
			for each (var profile:VideoProfile in videoProfiles) {
				dataProvider.addItem(profile);
			}
			dataProvider.refresh();
			view.cameraProfilesList.selectedIndex = dataProvider.getItemIndex(userSession.videoConnection.selectedCameraQuality);
		}
		
		private function userChangeHandler(user:User, type:int):void {
			if (user.me) {
				if (type == UserList.HAS_STREAM) {
					view.startCameraButton.label = ResourceManager.getInstance().getString('resources', user.hasStream ? 'profile.settings.camera.on' : 'profile.settings.camera.off');
					if (Camera.names.length > 1) {
						setSwapCameraButtonEnable(true)
					}
				}
			}
		}
		
		protected function onShareCameraClick(event:MouseEvent):void {
			setRotateCameraButtonEnable(userSession.userList.me.hasStream);
			setQualityListEnable(userSession.userList.me.hasStream);
			view.cameraProfilesList.selectedIndex = dataProvider.getItemIndex(userSession.videoConnection.selectedCameraQuality);
			shareCameraSignal.dispatch(!userSession.userList.me.hasStream, userSession.videoConnection.cameraPosition);
			displayPreviewCamera();
			if (userSession.videoAutoStart && !userSession.skipCamSettingsCheck) {
				userSession.videoAutoStart = false;
				userUISession.popPage();
			}
		}
		
		protected function onRotateCameraClick(event:MouseEvent):void {
			userSession.videoConnection.selectedCameraRotation += 90;
			if (userSession.videoConnection.selectedCameraRotation == 360) {
				userSession.videoConnection.selectedCameraRotation = 0;
			}
			saveData.save("cameraRotation", userSession.videoConnection.selectedCameraRotation);
			displayPreviewCamera();
		}
		
		protected function setSwapCameraButtonEnable(enabled:Boolean):void {
			view.swapCameraButton.enabled = enabled;
		}
		
		protected function setRotateCameraButtonEnable(enabled:Boolean):void {
			view.rotateCameraButton.enabled = enabled;
		}
		
		protected function setQualityListEnable(enabled:Boolean):void {
			view.cameraProfilesList.enabled = enabled;
		}
		
		protected function onCameraQualitySelected(event:IndexChangeEvent):void {
			if (event.newIndex >= 0) {
				var profile:VideoProfile = dataProvider.getItemAt(event.newIndex) as VideoProfile;
				if (userSession.userList.me.hasStream) {
					changeQualitySignal.dispatch(profile);
				} else {
					userSession.videoConnection.selectedCameraQuality = profile;
				}
				saveData.save("cameraQuality", userSession.videoConnection.selectedCameraQuality.id);
				displayPreviewCamera();
			}
		}
		
		private function isCamRotatedSideways():Boolean {
			return (userSession.videoConnection.selectedCameraRotation == 90 || userSession.videoConnection.selectedCameraRotation == 270);
		}
		
		private function displayPreviewCamera():void {
			var profile:VideoProfile = userSession.videoConnection.selectedCameraQuality
			var camera:Camera = getCamera(userSession.videoConnection.cameraPosition);
			if (camera) {
				var myCam:Video = new Video();
				var screenAspectRatio:Number = FlexGlobals.topLevelApplication.width / view.cameraSettingsScroller.height;
				if (screenAspectRatio > 1) { //landscape
					myCam.height = view.cameraSettingsScroller.height;
					myCam.width = profile.width * view.cameraSettingsScroller.height / profile.height;
				} else { //portrait
					myCam.width = FlexGlobals.topLevelApplication.width;
					myCam.height = profile.height * FlexGlobals.topLevelApplication.width / profile.width;
				}
				if (isCamRotatedSideways()) {
					camera.setMode(profile.height, profile.width, profile.modeFps);
					var temp = myCam.width;
					myCam.width = myCam.height;
					myCam.height = temp;
				} else {
					camera.setMode(profile.width, profile.height, profile.modeFps);
				}
				rotateObjectAroundInternalPoint(myCam, myCam.x + myCam.width / 2, myCam.y + myCam.height / 2, userSession.videoConnection.selectedCameraRotation);
				myCam.x = (FlexGlobals.topLevelApplication.width - myCam.width) / 2;
				if (userSession.videoConnection.selectedCameraRotation == 90) {
					myCam.y = 0;
					myCam.x = (FlexGlobals.topLevelApplication.width + myCam.width) / 2;
				} else if (userSession.videoConnection.selectedCameraRotation == 270) {
					myCam.y = myCam.height;
				} else if (userSession.videoConnection.selectedCameraRotation == 180) {
					myCam.x = (FlexGlobals.topLevelApplication.width + myCam.width) / 2;
					myCam.y = myCam.height;
				}
				myCam.attachCamera(camera);
				view.previewVideo.removeChildren();
				view.previewVideo.addChild(myCam);
				view.settingsGroup.y = myCam.height;
			} else {
				view.noVideoMessage.visible = true;
			}
		}
		
		public static function rotateObjectAroundInternalPoint(ob:Object, x:Number, y:Number, angleDegrees:Number):void {
			var point:Point = new Point(x, y);
			var m:Matrix = ob.transform.matrix;
			point = m.transformPoint(point);
			m.tx -= point.x;
			m.ty -= point.y;
			m.rotate(angleDegrees * (Math.PI / 180));
			m.tx += point.x;
			m.ty += point.y;
			ob.transform.matrix = m;
		}
		
		private function getCamera(position:String):Camera {
			for (var i:uint = 0; i < Camera.names.length; ++i) {
				var cam:Camera = Camera.getCamera(String(i));
				if (cam.position == position)
					return cam;
			}
			return Camera.getCamera();
		}
		
		/**
		 * Raised on button click, will send signal to swap camera source
		 **/
		//close old stream on swap
		private function mouseClickHandler(e:MouseEvent):void {
			if (!userSession.userList.me.hasStream) {
				if (String(userSession.videoConnection.cameraPosition) == CameraPosition.FRONT) {
					userSession.videoConnection.cameraPosition = CameraPosition.BACK;
				} else {
					userSession.videoConnection.cameraPosition = CameraPosition.FRONT;
				}
			} else {
				if (String(userSession.videoConnection.cameraPosition) == CameraPosition.FRONT) {
					shareCameraSignal.dispatch(!userSession.userList.me.hasStream, CameraPosition.FRONT);
					shareCameraSignal.dispatch(userSession.userList.me.hasStream, CameraPosition.BACK);
				} else {
					shareCameraSignal.dispatch(!userSession.userList.me.hasStream, CameraPosition.BACK);
					shareCameraSignal.dispatch(userSession.userList.me.hasStream, CameraPosition.FRONT);
				}
			}
			saveData.save("cameraPosition", userSession.videoConnection.cameraPosition);
			displayPreviewCamera();
		}
		
		override public function destroy():void {
			super.destroy();
			userSession.userList.userChangeSignal.remove(userChangeHandler);
			view.startCameraButton.removeEventListener(MouseEvent.CLICK, onShareCameraClick);
			if (Camera.names.length > 1) {
				view.swapCameraButton.addEventListener(MouseEvent.CLICK, mouseClickHandler);
			}
			view.cameraProfilesList.removeEventListener(ItemClickEvent.ITEM_CLICK, onCameraQualitySelected);
			view.dispose();
			view = null;
			userSession.videoAutoStart = false;
		}
	}
}
