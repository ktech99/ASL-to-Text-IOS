import cv2
import time
import os
# Create new folder of a certain sequence of images inside the img/ folder
# Note: Most have img/ folder inside the same directory as cam_capture
if not os.path.exists("img/"):  # Create img/ folder if doesn't already exists
    os.mkdir("img/")
sign_name = raw_input("Name of the sign language gesture? ")
person_name = raw_input("Name of the person? ")
if not os.path.exists("img/" + sign_name + "/"):
    os.mkdir("img/" + sign_name + "/")
path = "img/" + sign_name + "/" + person_name + "/"
if not os.path.exists(path):
    os.mkdir(path)
for timer in range(3,0,-1):
    print(timer)
    time.sleep(1)
camera = cv2.VideoCapture(0)
time.sleep(.5)
for i in range(50):
    return_value, image = camera.read()
    cv2.imwrite('img/' + sign_name + "/" + person_name + "/" + person_name + "-" + str(i) + '.png', image)
    time.sleep(.050)
camera.release()