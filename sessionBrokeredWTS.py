#!/usr/bin/python

from Tkinter import *
import subprocess 
from subprocess import call
import re
import tkMessageBox
import tkFont
from PIL import Image, ImageTk

cmdWhoami = subprocess.Popen(["whoami"], stdout=subprocess.PIPE)
username, resWhomai = cmdWhoami.communicate()

username = username.rstrip()

resPBIScall = []

cmdPBIScall = subprocess.Popen(["/opt/pbis/bin/find-user-by-name", "--level", "2", username], stdout=subprocess.PIPE)

for line in iter(cmdPBIScall.stdout.readline, ''):
	resPBIScall.append(line.rstrip())

# search for the line ^UPN then split that based on ':<whitespacehere>'

upn = resPBIScall[4].split()
username = upn[1]

# Set up the gui
root = Tk()
root.wm_title("lonwts.onshore.pgs.com")
root.wm_geometry("250x400")
root.resizable(width = False, height = False)

frameTop = Frame(root)
frameTop.grid()

frameMiddle = Frame(root)
frameMiddle.grid()

frameBottom = Frame(root)
frameBottom.grid()

fileLogo = Image.open('/users/storres/scripts/pgslogo.jpg')
tkimage = ImageTk.PhotoImage(fileLogo)


labelUsername = Label(frameTop, text = "Username: " + username)
labelUsername.grid()

labelMenu = Label(frameTop, text = "Resolutions")

resolutionList = OptionMenu(frameMiddle, "1024x768", "1600x1200", "1440x900")
resolutionList.grid()
labelMenu.grid()

labelPassword = Label(frameMiddle, text="Password")
labelPassword.grid()

entryPassword = Entry(frameMiddle, show="*")
entryPassword.grid()

logo = Label(frameBottom, image = tkimage)
logo.grid()


def login():
	root.wm_withdraw()
	resolution = resolutionList.get()
	password = entryPassword.get()
	# Want to fork this process, so the window is released.
	call(["rdesktop", "-u", username, "-p", password, "-r", "disk:local=/local", "-r", "clipboard:PRIMARYCLIPBOARD","-a", "16", "-g", resolution, "HOSTNAME"])
	exit()

buttonLogin = Button(frameMiddle, text="Login", command=login)
buttonLogin.grid()

root.mainloop()
