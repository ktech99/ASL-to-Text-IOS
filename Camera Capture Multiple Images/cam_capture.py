import cv2
import time
import os
# Create new folder of a certain sequence of images inside the img/ folder
# Note: Most have img/ folder inside the same directory as cam_capture

file_name = raw_input("Name of the sign language gesture? ")
path = "img/" + file_name + "/"
os.mkdir(path)
for timer in range(3,0,-1):
    print(timer)
    time.sleep(1)
camera = cv2.VideoCapture(0)
for i in range(15):
    return_value, image = camera.read()
    cv2.imwrite('img/' + file_name + "/" + file_name + "-" + str(i) + '.png', image)
    time.sleep(.100)
camera.release()