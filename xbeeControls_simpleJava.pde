import java.awt.Frame;
/*
  Modified Madsci:
  
  Removed all display logic and just grab sensor data
*/

//SMOOTHING VALUES
int smooth_numReadings = 3;
int[] smooth_readings = new int[smooth_numReadings];      // the readings from the analog input
int smooth_index = 0;                          // the index of the current reading
int smooth_total = 0;                        // the running total
int smooth_average = 0;

boolean DEBUG = false;
boolean XBEE = false;
int whichMachine = 2;
int USB_PORT = 0;
static int TOTAL_WIDTH = 2*1280;

String machineRoot = "";

// 0 is Rui
// 1 is Adam
// 2 is Mini

/******************
 PONG VARIABLES
******************/
boolean doubleP = false;
boolean seizureMode = false;
 
int colorVal;
 
float dbx = 450; //demo ball - start screen
float dby = 300;
float dbSpeedX = 8;
float dbSpeedY = 8;
 
float ballX = 450; //playing ball
float ballY = 300;
float x1 = 45; //player 1 coordinates (left)
float y1 = 255;
float x2 = 845; //player 2 coordinates (right)
float y2 = 255;
float speed = 9;
 
float ballSpeedX = 4.5;
float ballSpeedY = 4.5;
boolean ballTouchingP1 = false;
boolean ballTouchingP2 = false;


int minX,maxX,minY,maxY;

 
boolean wPressed = false;
boolean sPressed = false;
boolean iPressed = false;
boolean kPressed = false;
boolean goPressed = false; //space starts the ball
boolean mPressed = false; //'m' changes the background color mode
 
int p1Score = 0;
int p2Score = 0;


// used for communication via xbee api
import processing.serial.*; 

// xbee api libraries available at http://code.google.com/p/xbee-api/
// Download the zip file, extract it, and copy the xbee-api jar file 
// and the log4j.jar file (located in the lib folder) inside a "code" 
// folder under this Processing sketch’s folder (save this sketch, then 
// click the Sketch menu and choose Show Sketch Folder).
import com.rapplogic.xbee.api.ApiId;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

//Paddles
String leftAddress = "00:13:a2:00:40:97:1e:80";
String rightAddress = "";

int leftVal = 0;
int rightVal = 0;

int leftDiff = 0;
int rightDiff = 0;

String version = "1.1";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***

String mySerialPort;

// create and initialize a new xbee object
XBee xbee = new XBee();

int error=0;

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();
// create a font for display
PFont font;

SimpleThread testThread;


 
static public void main(String args[]) {
  Frame frame = new Frame("testing");
  frame.setUndecorated(true);
  // The name "sketch_name" must match the name of your program
  PApplet applet = new xbeeControls_simpleJava();
  frame.add(applet);
  applet.init();
  frame.setBounds(0, 0, TOTAL_WIDTH, 720); 
  frame.setVisible(true);
}


void setup() {
  background(0);
  
  if (XBEE == true) {
    mySerialPort = Serial.list()[USB_PORT];
  }

  for (int thisReading = 0; thisReading < smooth_numReadings; thisReading++)
  {
    smooth_readings[thisReading] = 0; 
  }
  
  switch(whichMachine){
  case 0:      // Rui
    machineRoot  = "/Users/rui pereira/Documents/Processing/xbeeControls_simpleJava/";
  break;
  case 1:      // Adam
    machineRoot  = "/Users/adam lassy/Documents/Processing/xbeeControls_simpleJava/";
  break;
  case 2:      // Mini
    machineRoot  = "/Users/madscience/Documents/Processing/xbeeControls_simpleJava/";
  break;
  }
  
  font = loadFont(machineRoot + "data/CasaleTwo-Alternates-NBP-100.vlw");
  
  size(TOTAL_WIDTH, 720);
  minX = 0;
  maxX = width;
  minY = 0;
  maxY = height;
  
  ballX = width*.5; //playing ball
  ballY = height*.5;
  x1 = 45; //player 1 coordinates (left)
  y1 = (height-90)*.5;
  x2 = width-45; //player 2 coordinates (right)
  y2 = (height-90)*.5;
  speed = 9;


  // The log4j.properties file is required by the xbee api library, and 
  // needs to be in your data folder. You can find this file in the xbee
  // api library you downloaded earlier
  PropertyConfigurator.configure(machineRoot + "data/log4j.properties"); 
  // Print a list in case the selected one doesn't work out
  println("Available serial ports:");
  println(Serial.list());
  
  //Create Thread
  testThread = new SimpleThread(10,"controlThread");
  
  if (XBEE) {
    testThread.start();
  }
  
  //smooth();
  
  frameRate(60);
  noCursor();


}

int smooth_left(int _val)
{
  smooth_total= smooth_total - smooth_readings[smooth_index];         
  // read from the sensor:  
  smooth_readings[smooth_index] = _val; 
  // add the reading to the total:
  smooth_total= smooth_total + smooth_readings[smooth_index];       
  // advance to the next position in the array:  
  smooth_index = smooth_index + 1;                    

  // if we're at the end of the array...
  if (smooth_index >= smooth_numReadings)              
    // ...wrap around to the beginning: 
    smooth_index = 0;                           

  // calculate the average:
  return smooth_total / smooth_numReadings;
}

// draw loop executes continuously
void draw() {
  /*
     GET LEFT AND RIGHT VALS, PASSING IN THE DESIRED RANGE
  */
  //int _leftVal = getLeftVal(1,100);  
  
  //int _rightVal = getRightVal(1,100);
  

  //PONG LOOP
  twoPlayer();
  
  /*
    Xbee Error Reporting
  */
  if (error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code near line 20?", width/3, height/2);
  }
  
  if (DEBUG == true) {
    text(leftVal,10,50);
    text(rightVal,width-100,50);
  }
  
} // end of draw loop


// defines the data object
class SensorData {
  int value;
  String address;
}

// queries the XBee for incoming I/O data frames 
// and parses them into a data object
SensorData getData() {

  SensorData data = new SensorData();
  int value = -1;      // returns an impossible value if there's an error
  String address = ""; // returns a null value if there's an error

  try {
 
    // we wait here until a packet is received.
    XBeeResponse response = xbee.getResponse();
    // uncomment next line for additional debugging information
    //println("Received response " + response.toString()); 

    // check that this frame is a valid I/O sample, then parse it as such
    if (response.getApiId() == ApiId.ZNET_IO_SAMPLE_RESPONSE 
      && !response.isError()) {
      ZNetRxIoSampleResponse ioSample = 
        (ZNetRxIoSampleResponse)(XBeeResponse) response;

      // get the sender's 64-bit address
      int[] addressArray = ioSample.getRemoteAddress64().getAddress();
      // parse the address int array into a formatted string
      String[] hexAddress = new String[addressArray.length];
      for (int i=0; i<addressArray.length;i++) {
        // format each address byte with leading zeros:
        hexAddress[i] = String.format("%02x", addressArray[i]);
      }

      // join the array together with colons for readability:
      String senderAddress = join(hexAddress, ":"); 
      //print("Sender address: " + senderAddress);
      
      data.address = senderAddress;
      // get the value of the first input pin
      value = ioSample.getAnalog0();
      
      //print(value + "\n"); 
      data.value = value;
    }
    else if (!response.isError()) {
      println("Got error in data frame");
    }
    else {
      println("Got non-i/o data frame");
    }
  }
  catch (XBeeException e) {
    println("Error receiving response: " + e);
  }
  return data; // sends the data back to the calling function
}

int getLeftVal(int rangeLow, int rangeHigh)
{
     return (int)map(leftVal, 0, 1023, rangeLow, rangeHigh);
}
  
  
int getRightVal(int rangeLow, int rangeHigh)
{
     return (int)map(rightVal, 0, 1023, rangeLow, rangeHigh);
}
  
  /************
  THREAD SHIT
  *************/
  
class SimpleThread extends Thread {
 
  boolean running;           // Is the thread running?  Yes or no?
  int wait;                  // How many milliseconds should we wait in between executions?
  String id;                 // Thread name
  int count;                 // counter


  // Constructor, create the thread
  // It is not running by default
  SimpleThread (int w, String s) {
    wait = w;
    running = false;
    id = s;
    count = 0;
  }
 
  int getCount() {
    return count;
  }
 
  // Overriding "start()"
  void start () {

    
      try {
    // opens your serial port defined above, at 9600 baud
    xbee.open(mySerialPort, 19200);
  }
  catch (XBeeException e) {
    println("** Error opening XBee port: " + e + " **");
    println("Is your XBee plugged in to your computer?");
    println("Did you set your COM port in the code near line 20?");
    error=1;
  }
  
    // Set running equal to true
    running = true;
    // Print messages
    println("Starting thread (will execute every " + wait + " milliseconds.)");

    // Do whatever start does in Thread, don't forget this!
    super.start();
    
    println("START");


  }
  
  // We must implement run, this gets triggered by start()
  void run () {
   
    while (running) {
      //println(id + ": " + count);
      //count++;
      // Ok, let's wait for however long we should wait
      
        SensorData data = new SensorData(); // create a data object
  data = getData(); // put data into the data object
  
  //println(">" + data.value);

  // check that actual data came in:
  if (data.value >=0 && data.address != null) { 
    
    //println ("Address: >" + data.address + "<  >" + leftAddress + "<");
    if (data.address.equals(leftAddress) == true) {
      
      //leftDiff = abs(data.value - leftVal);
      leftVal = data.value;
      //leftVal = smooth_left(data.value);
 
    } else {

      //rightDiff = abs(data.value - rightVal);
      rightVal = data.value;
    }
    //println ("Address: " + data.address + " : " + data.value);
  }
  
      try {
        sleep((long)(wait));
      } catch (Exception e) {
      }
    }
  

    //System.out.println(id + " thread is done!");  // The thread is done when we get to the end of run()
    
  }
 
 
  // Our method that quits the thread
  void quit() {
    System.out.println("Quitting."); 
    running = false;  // Setting running to false ends the loop in run()
    // IUn case the thread is waiting. . .
    interrupt();
  }
}

/************************
PONG FUNCTIONS
**************************/

void demoBall() {
  noStroke();
  fill(255,0,0);
  rectMode(CENTER);
  rect(dbx,dby,40,40);
    fill(random(0,255),random(0,255),random(0,255));
//  rect(dbx,dby,40,40);
   
  dbx = dbx + dbSpeedX;
  dby = dby + dbSpeedY;
   
  if (dbx >= maxX) {
    dbSpeedX = dbSpeedX * -1;
  }
  if (dbx <= minX) {
    dbSpeedX = dbSpeedX * -1;
  }
  if (dby >= maxY) {
    dbSpeedY = dbSpeedY * -1;
  }
  if (dby <= minY) {
    dbSpeedY = dbSpeedY * -1;
  }
}

void twoPlayer() {
  background(random(0,colorVal),random(0,colorVal),random(0,colorVal));
  midLine();
  player1();
  player2();
  ball();
   
  textFont (font);
  textAlign(CENTER);
  text(""+p1Score,225,80);
  text(""+p2Score,width-225,80);
   
  if (mPressed == true) {
    seizureMode = true;
  }
  if (seizureMode == true) {
    colorVal = 255;
  }
  if (seizureMode == false) {
    colorVal = 0;
  }
}

 
 
//
void midLine() {
  for (int i = 0; i < 1000; i = i+20) {
    fill(255);
    rect(width*.5,i,2,10);
  }
}
 
 
 
 
//
void player1() {
  rectMode(CENTER);
  fill(255);
  rect(x1,y1,15,90);
   
  y1 = getLeftVal(1,height-45);
  
  /* 
  if (y1 <= 0) {
    y1 = 0;
  }
  if (y1 >= 510) {
    y1 = 510;
  }
  
  if (wPressed == true) {
    y1 = y1 - speed;
  }
  if (sPressed == true) {
    y1 = y1 + speed;
  }
  */
  
}
 
 
void player2() {
  rectMode(CENTER);
  fill(255);
  rect(x2,y2,15,90);
   
  y2 = getRightVal(1,height-45);
   
   /*
  if (y2 <= 0) {
    y2 = 0;
  }
  if (y2 >= 510) {
    y2 = 510;
  }
   
  if (iPressed == true) {
    y2 = y2 - speed;
  }
  if (kPressed == true) {
    y2 = y2 + speed;
  }
  */
  
}
 
void ball() {
  noStroke();
  ellipseMode(CENTER);
  fill(255,0 ,0);
  ellipse(ballX, ballY, 15, 15);
  rectMode(CENTER);
  fill(255);
  rect(ballX, ballY, 15, 15); 
   
  if (goPressed == true) {
    ballX = ballX + ballSpeedX;
    ballY = ballY + ballSpeedY;
  }
   
  if (ballY >= maxY) {
    ballSpeedY = ballSpeedY * -1;
  }
  if (ballY <= minY) {
    ballSpeedY = ballSpeedY * -1;
  }
   
  if ((ballX <= minX+60) && (ballX >= minX+45) && (ballY >= y1) && (ballY <= y1+90)) {
    ballTouchingP1 = true;
  }
  if ((ballX >= maxX -60) && (ballX <= maxX-45) && (ballY >= y2) && (ballY <= y2+90)) {
    ballTouchingP2 = true;
  }
   
  if (ballTouchingP1 == true) {
    ballSpeedX = ballSpeedX * -1;
    ballTouchingP1 = false;
  }
  if (ballTouchingP2 == true) {
    ballSpeedX = ballSpeedX * -1;
    ballTouchingP2 = false;
  }
   
  if (ballX >= maxX) {
    ballX = width*.5;;
    ballSpeedX = ballSpeedX * -1;
    p1Score = p1Score + 1;
  }
  if (ballX <= minX) {
    ballX = width*.5;
    ballSpeedX = ballSpeedX * -1;
    p2Score = p2Score + 1;
  }
}

void keyPressed() {
  if (key == 'w') {
    wPressed = true;
  }
  if (key == 's') {
    sPressed = true;
  }
  if (key =='i') {
    iPressed = true;
  }
  if (key == 'k') {
    kPressed = true;
  }
  if (key == ' ') {
    goPressed = true;
  }
  if (key == 'm') {
    mPressed = true;
  }
}

