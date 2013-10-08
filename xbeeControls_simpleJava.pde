/*
 * Draws a set of thermometers for incoming XBee Sensor data
 * by Rob Faludi http://faludi.com
 */

/*
  Modified Madsci:
  
  Removed all display logic and just grab sensor data
*/

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

String version = "1.1";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***

String mySerialPort = Serial.list()[4];
  
// create and initialize a new xbee object
XBee xbee = new XBee();

int error=0;

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();
// create a font for display
PFont font;

SimpleThread testThread;

void setup() {
  size(900,600); // screen size

  // The log4j.properties file is required by the xbee api library, and 
  // needs to be in your data folder. You can find this file in the xbee
  // api library you downloaded earlier
  PropertyConfigurator.configure(dataPath("")+"/log4j.properties"); 
  // Print a list in case the selected one doesn't work out
  println("Available serial ports:");
  println(Serial.list());
  
  //Create Thread
  testThread = new SimpleThread(0,"controlThread");
  testThread.start();
  
  smooth();
  
  frameRate(50);
}


// draw loop executes continuously
void draw() {
  /*
     GET LEFT AND RIGHT VALS, PASSING IN THE DESIRED RANGE
  */
  int _leftVal = getLeftVal(1,100);  
  text(_leftVal,10,50);
  
  int _rightVal = getRightVal(1,100);
  text(_rightVal,width-100,50);

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
    xbee.open(mySerialPort, 9600);
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
      leftVal = data.value; 
    } else {
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
  fill(random(0,255),random(0,255),random(0,255));
  ellipse(dbx,dby,40,40);
   
  dbx = dbx + dbSpeedX;
  dby = dby + dbSpeedY;
   
  if (dbx >= 900) {
    dbSpeedX = dbSpeedX * -1;
  }
  if (dbx <= 0) {
    dbSpeedX = dbSpeedX * -1;
  }
  if (dby >= 600) {
    dbSpeedY = dbSpeedY * -1;
  }
  if (dby <= 0) {
    dbSpeedY = dbSpeedY * -1;
  }
}

void twoPlayer() {
  background(random(0,colorVal),random(0,colorVal),random(0,colorVal));
  midLine();
  player1();
  player2();
  ball();
   
  PFont font;
  font  = loadFont("Futura-CondensedMedium-100.vlw");
  textFont (font);
  textAlign(CENTER);
  text(""+p1Score,225,80);
  text(""+p2Score,675,80);
   
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
    rect(449,i,2,10);
  }
}
 
 
 
 
//
void player1() {
  fill(255);
  rect(x1,y1,10,90);
   
  y1 = getLeftVal(1,510);
  
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
  fill(255);
  rect(x2,y2,10,90);
   
  y2 = getRightVal(1,510);
   
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
  ellipseMode(CENTER);
  fill(255);
  ellipse(ballX, ballY, 15, 15);
   
  if (goPressed == true) {
    ballX = ballX + ballSpeedX;
    ballY = ballY + ballSpeedY;
  }
   
  if (ballY >= 600) {
    ballSpeedY = ballSpeedY * -1;
  }
  if (ballY <= 0) {
    ballSpeedY = ballSpeedY * -1;
  }
   
  if ((ballX <= 60) && (ballX >= 45) && (ballY >= y1) && (ballY <= y1+90)) {
    ballTouchingP1 = true;
  }
  if ((ballX >= 840) && (ballX <= 855) && (ballY >= y2) && (ballY <= y2+90)) {
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
   
  if (ballX >= 900) {
    ballX = 450;
    ballSpeedX = ballSpeedX * -1;
    p1Score = p1Score + 1;
  }
  if (ballX <= 0) {
    ballX = 450;
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

