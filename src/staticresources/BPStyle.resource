/* This is for the full screen DIV */
.popupBackground {
    /* Background color */
    background-color:black;
    opacity: 0.20;
    filter: alpha(opacity = 20);
   
    /* Dimensions */
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    z-index: 998;
    position: absolute;
       
    /* Mouse */
    cursor:wait;
}

/* This is for the message DIV */
.popupPanel {
    /* Background color */
    border: solid 5px black;
    background-color: white;

    /* Dimensions */
    left: 50%;
    width: 300px;
    margin-left: -100px;
    top: 50%;
    height: 50px;
    margin-top: -25px;
    z-index: 999;
    position: fixed;
       
    /* Mouse */
    cursor:pointer;
}
