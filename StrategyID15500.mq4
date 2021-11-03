//+------------------------------------------------------------------+
//|                                              StrategyID15500.mq4 |
//|                                            True Alpha Technogloy |
//|                                              http://truealpha.cc |
//+------------------------------------------------------------------+
#property copyright "True Alpha Technogloy"
#property link      "http://truealpha.cc"
#property version   "1.00"//20211103

//#region Private Variables
// common price
double CurrAsk = 0;

double CurrBid = 0;

double CurrMid = 0;

double CurrSpread = 0;

// common strategy
string StrategyID = "11512";

string CurrMagicNumber = "11512";

int Currdigits = 5;

double CurrPtsValue = 0.00001;

double CurrPtsToInt = 100000;

// common trade
double InUseLot = 0.01;

double LotFactorList[]= {1,1,1,1,1,1,1,1,1,1,1,1};

double TargetPriceFactor = 1;

double TargetPriceFactorList[]= {1,1,1,1,1,1,1,1,1,1,1,1};

int CurrTN = 0;

string InUseComment;

string IsAllowedToTrade;

// virtual trade related
double ActionPrice_B = 0;

double ActionPrice_S = 0;

int CurrBarTradeCount_BV = 0;

int CurrBarTradeCount_SV = 0;

int Buy_VirtualLevel = 0;

double Buy_VirtualFinishPrice = 0;

double Buy_VirtualStepPrice = 0;

int Sell_VirtualLevel = 0;

double Sell_VirtualFinishPrice = 0;

double Sell_VirtualStepPrice = 0;

//MT4 special
string CurrSymbol = "EURUSD";

datetime ArrayTime[], LastTime;
//#endregion


//#region User Defined Para
extern double Quantity = 0.01 ;

extern int MaxTradeCount = 9;

extern double MaxSpreadAllowed = 36;

extern int AllowedTN = 60000 ;

extern int CMD = -1;

extern int AllowedDeviation = 10 ;

extern double CurrStepPts = 120;

extern int TriggerTradeCount = 5;

extern int MinDTE = 60;

extern double LF1 = 1;

extern double LF2 = 1;

extern double LF3 = 1.5;

extern double LF4 = 3.5;

extern double LF5 = 7;

extern double LF6 = 14;

extern double LF7 = 28;

extern double LF8 = 56;

extern double LF9 = 60;

extern double LF10 = 70;

extern double LF11 = 80;

extern double LF12 = 90;
//#endregion


//#region Events
int OnInit()
  {
   CurrSymbol = StringSubstr(_Symbol,0,6);

   CurrMagicNumber = getMagicNumber(StrategyID);

   Currdigits = (int)MarketInfo(CurrSymbol,MODE_DIGITS);

   CurrPtsToInt = MathPow(10,Currdigits);

   CurrPtsValue = 1 / MathPow(10,Currdigits);

// process lot factor
   LotFactorList[0] = LF1;
   LotFactorList[1] = LF2;
   LotFactorList[2] = LF3;
   LotFactorList[3] = LF4;
   LotFactorList[4] = LF5;
   LotFactorList[5] = LF6;
   LotFactorList[6] = LF7;
   LotFactorList[7] = LF8;
   LotFactorList[8] = LF9;
   LotFactorList[9] = LF10;

   setChartBackground();

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   string CurrTime = IntegerToString(Time[0]);

   string NowComm = "A" + IntegerToString(AccountNumber()) + "X" + CurrTime;

   CurrAsk = MarketInfo(CurrSymbol,MODE_ASK);

   CurrBid = MarketInfo(CurrSymbol,MODE_BID);

   CurrMid = (CurrAsk + CurrBid)/2;

   CurrSpread = (CurrAsk - CurrBid) * CurrPtsToInt;

   string TradeSignal = GetTradeSignal_15500(CurrTime);

   if(TradeCount(-1) >= 1)
     {
      InUseLot = getInUseLot(TradeCount(-1));
     }

// check whether is ok to trade
   IsAllowedToTrade = CheckTradeSginalPass_15500_Special();

// Main
   if(StringFind(TradeSignal,"FinishPos")>=0)
     {
      if(TradeCount(0) > 0)
        {
         Close_MT4(CurrMagicNumber, 0);

         ActionPrice_B = 0;
        }
     }

   if(StringFind(TradeSignal,"Buy")>=0)
     {
      ActionPrice_B = CurrAsk;
     }

   if(TradeCount(-1) == 0 && ActionPrice_B > 0 && IsAllowedToTrade == "Yes")
     {
      double BAU = ActionPrice_B + AllowedDeviation * CurrPtsValue;

      double BAB = ActionPrice_B - AllowedDeviation * CurrPtsValue;

      if(CurrAsk <= BAU && CurrAsk >= BAB)
        {
         Open_MT4(CurrMagicNumber, 0, Quantity, NowComm);

         CurrTN = CurrTN + 1;

         InUseComment = NowComm;

         ActionPrice_B = 0;
        }
      else
        {
         Print("unable to buy place order");
        }
     }

   if(StringFind(TradeSignal,"FinishNeg")>=0)
     {
      if(TradeCount(1) > 0)
        {
         Close_MT4(CurrMagicNumber, 1);

         ActionPrice_S = 0;
        }
     }

   if(StringFind(TradeSignal,"Sell")>=0)
     {
      ActionPrice_S = -1 * CurrBid;
     }

   if(TradeCount(-1) == 0 && ActionPrice_S < 0 && IsAllowedToTrade == "Yes")
     {
      double SAU = MathAbs(ActionPrice_S) + AllowedDeviation * CurrPtsValue;

      double SAB = MathAbs(ActionPrice_S) - AllowedDeviation * CurrPtsValue;

      if(CurrBid <= SAU && CurrBid >= SAB)
        {
         Open_MT4(CurrMagicNumber, 1, Quantity, NowComm);

         CurrTN = CurrTN + 1;

         InUseComment = NowComm;

         ActionPrice_S = 0;
        }
      else
        {
         Print("unable to place sell order");
        }
     }

   if(StringFind(TradeSignal,"PosLevelUp")>=0)
     {
      if(TradeCount(0) > 0 && TradeCount(0) < MaxTradeCount)
        {
         ActionPrice_B = CurrAsk;
        }

      if(TradeCount(0) == MaxTradeCount)
        {
         Close_MT4(CurrMagicNumber, 0);

         ActionPrice_B = 0;
        }
     }

   if(StringFind(TradeSignal,"NegLevelDown")>=0)
     {
      if(TradeCount(1) > 0 && TradeCount(1) < MaxTradeCount)
        {
         ActionPrice_S = CurrBid;
        }

      if(TradeCount(1) == MaxTradeCount)
        {
         Close_MT4(CurrMagicNumber, 1);

         ActionPrice_S = 0;
        }
     }

   if(TradeCount(-1) > 0)
     {
      if(ActionPrice_B > 0 && TradeCount(0) > 0 && CurrAsk >= ActionPrice_B - AllowedDeviation * CurrPtsValue && CurrAsk <= ActionPrice_B + AllowedDeviation * CurrPtsValue)
        {
         Open_MT4(CurrMagicNumber, 0, InUseLot, InUseComment);

         ActionPrice_B = 0;
        }

      if(ActionPrice_S > 0 && TradeCount(1) > 0 && CurrBid >= ActionPrice_S - AllowedDeviation * CurrPtsValue && CurrBid <= ActionPrice_S + AllowedDeviation * CurrPtsValue)
        {
         Open_MT4(CurrMagicNumber, 1, InUseLot, InUseComment);

         ActionPrice_S = 0;
        }
     }

   drawInfo();

// ctrader onBar
   if(NewBar(5))
     {
      CurrBarTradeCount_BV = 0;

      CurrBarTradeCount_SV = 0;
     }
  }
//#endregion


//#region Time Validation Logic

//#endregion


//#region Position Management

//#endregion


//#region  Function
// strategy specific
string GetTradeSignal_15500(string InCurrTime)
  {
   string RR_GTS = "No";

   string CurrMid_S = DoubleToStr(MathRound(CurrMid * CurrPtsToInt),0);

   string Last4digitsPrice = "," + StringSubstr(CurrMid_S,StringLen(CurrMid_S)-4,4);

   double Close_1 = iClose(CurrSymbol,5,1);

   double EMA_M5_200_1 = iMA(CurrSymbol,5,200,0,MODE_EMA,PRICE_CLOSE,1);

   TargetPriceFactor = 1;

//initiate virtual
// no trade count buy
   if(TradeCount(0) == 0)
     {
      if(Buy_VirtualLevel == 0)
        {
         if(Close_1 >= EMA_M5_200_1 + MinDTE * CurrPtsValue && CurrSpread <= MaxSpreadAllowed)
           {
            Buy_VirtualLevel = Buy_VirtualLevel + 1;

            CurrBarTradeCount_BV = CurrBarTradeCount_BV + 1;

            Buy_VirtualFinishPrice = CurrBid + CurrStepPts * CurrPtsValue;

            Buy_VirtualStepPrice = CurrAsk - CurrStepPts * CurrPtsValue;

            drawText(InCurrTime + "BV",TimeCurrent(),CurrMid,"B" + Buy_VirtualLevel + Last4digitsPrice,Red);
           }
        }
     }

   if(TradeCount(1) == 0)
     {
      if(Sell_VirtualLevel == 0)
        {
         if(Close_1 < EMA_M5_200_1 - MinDTE * CurrPtsValue && CurrSpread <= MaxSpreadAllowed)
           {
            Sell_VirtualLevel = Sell_VirtualLevel + 1;

            CurrBarTradeCount_SV = CurrBarTradeCount_SV + 1;

            Sell_VirtualFinishPrice = CurrAsk - CurrStepPts * CurrPtsValue;

            Sell_VirtualStepPrice = CurrBid + CurrStepPts * CurrPtsValue;

            drawText(InCurrTime + "SV",TimeCurrent(),CurrMid,"S" + Sell_VirtualLevel + Last4digitsPrice,Blue);
           }
        }
     }

   if(Buy_VirtualLevel > 0)
     {
      if(CurrBid >= Buy_VirtualFinishPrice)
        {
         RR_GTS = "FinishPos";

         Buy_VirtualLevel = 0;

         DrawWingdingsObject(InCurrTime + "BVF",TimeCurrent(),CurrMid,clrRed,120);
        }

      if(CurrAsk <= Buy_VirtualStepPrice && CurrBarTradeCount_BV < 2)
        {
         RR_GTS = RR_GTS + "PosLevelUp";

         Buy_VirtualLevel = Buy_VirtualLevel + 1;

         CurrBarTradeCount_BV = CurrBarTradeCount_BV + 1;

         Buy_VirtualFinishPrice = CurrBid + TargetPriceFactor * CurrStepPts * CurrPtsValue;

         Buy_VirtualStepPrice = CurrAsk - CurrStepPts * CurrPtsValue;

         drawText(InCurrTime + "BV",TimeCurrent(),CurrMid,"B" + Buy_VirtualLevel + Last4digitsPrice,Red);
        }
     }

   if(Sell_VirtualLevel > 0)
     {
      if(CurrAsk <= Sell_VirtualFinishPrice)
        {
         RR_GTS = RR_GTS + "FinishNeg";

         Sell_VirtualLevel = 0;

         DrawWingdingsObject(InCurrTime + "SVF",TimeCurrent(),CurrMid,clrBlue,120);
        }

      if(CurrBid >= Sell_VirtualStepPrice && CurrBarTradeCount_SV < 2)
        {
         RR_GTS = RR_GTS + "NegLevelDown";

         Sell_VirtualLevel = Sell_VirtualLevel + 1;

         CurrBarTradeCount_SV = CurrBarTradeCount_SV + 1;

         Sell_VirtualFinishPrice = CurrAsk - TargetPriceFactor * CurrStepPts * CurrPtsValue;

         Sell_VirtualStepPrice = CurrBid + CurrStepPts * CurrPtsValue;

         drawText(InCurrTime + "SV",TimeCurrent(),CurrMid,"S" + Sell_VirtualLevel + Last4digitsPrice,Blue);
        }
     }

   if(TradeCount(-1) == 0 && Buy_VirtualLevel == TriggerTradeCount && CurrSpread <= MaxSpreadAllowed)
     {
      if(CMD == 0 || CMD == -1)
        {
         int A = StringReplace(RR_GTS,"PosLevelUp"," Buy");
        }
     }

   if(TradeCount(-1) == 0 && Sell_VirtualLevel == TriggerTradeCount && CurrSpread <= MaxSpreadAllowed)
     {
      if(CMD == 1 || CMD == -1)
        {
         int B = StringReplace(RR_GTS,"NegLevelDown"," Sell");
        }
     }

   return RR_GTS;
  }

// common below
// standand close
void Close_MT4(string InMagicNumber, int InCMD = -1)
  {
   bool CloseCheck = 0;

   if(InCMD == -1)
     {
      for(int i_CAT = OrdersTotal()-1; i_CAT>=0; i_CAT--)
        {
         if(OrderSelect(i_CAT,SELECT_BY_POS,MODE_TRADES) == TRUE)
           {
            if(OrderMagicNumber() == StrToInteger(InMagicNumber))
              {
               if(OrderType()==0)
                 {
                  CloseCheck = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),6,Red);
                 }
               if(OrderType()==1)
                 {
                  CloseCheck = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),6,Red);
                 }
              }
           }
        }
     }

   if(InCMD == 0)
     {
      for(int i0 = OrdersTotal()-1; i0>=0; i0--)
        {
         if(OrderSelect(i0,SELECT_BY_POS,MODE_TRADES) == TRUE)
           {
            if(OrderMagicNumber() == StrToInteger(InMagicNumber))
              {
               if(OrderType()==0)
                 {
                  CloseCheck = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),6,Red);
                 }
              }
           }
        }
     }

   if(InCMD == 1)
     {
      for(int i1 = OrdersTotal()-1; i1>=0; i1--)
        {
         if(OrderSelect(i1,SELECT_BY_POS,MODE_TRADES) == TRUE)
           {
            if(OrderMagicNumber() == StrToInteger(InMagicNumber))
              {
               if(OrderType()==1)
                 {
                  CloseCheck = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),6,Red);
                 }
              }
           }
        }
     }

  }

// standard open
void Open_MT4(string InMagicNumber, int InCMD, double xInUseLot, string InC, int InSLpips = 1000, int InTPpips = 1000)
  {

   int RNOS = 0 ;

   if(InCMD == 0)
     {
      RNOS = OrderSend(_Symbol,InCMD,xInUseLot,CurrAsk,6,
                       MathMax(NormalizeDouble((CurrAsk - InSLpips * 10 * CurrPtsValue),Currdigits),0),
                       MathMax(NormalizeDouble((CurrAsk + InTPpips * 10 * CurrPtsValue),Currdigits),0),
                       InC,StrToInteger(InMagicNumber),0,Blue);
     }

   if(InCMD == 1)
     {
      RNOS = OrderSend(_Symbol,InCMD,xInUseLot,CurrBid,6,
                       MathMax(NormalizeDouble((CurrBid + InSLpips * 10 * CurrPtsValue),Currdigits),0),
                       MathMax(NormalizeDouble((CurrBid - InTPpips * 10 * CurrPtsValue),Currdigits),0),
                       InC,StrToInteger(InMagicNumber),0,Red);
     }
  }

// standard tradecount
int TradeCount(int InCMD, string InMagicNumber = NULL)
  {
   int RN_RN = 0;

   int RN_TC = 0;

   int RN_Buy =0 ;

   int RN_Sell = 0;

   if(InMagicNumber == NULL)
     {
      InMagicNumber = CurrMagicNumber;
     }

   for(int i_GTC = OrdersTotal() -1; i_GTC >= 0; i_GTC --)
     {
      if(OrderSelect(i_GTC,SELECT_BY_POS,MODE_TRADES) == TRUE)
        {
         if(OrderMagicNumber() == StrToInteger(InMagicNumber))
           {
            if(OrderType() == 0)
              {
               RN_Buy = RN_Buy +1;
              }
            if(OrderType() == 1)
              {
               RN_Sell = RN_Sell +1;
              }
           }
        }
     }

   RN_TC = RN_Buy + RN_Sell;

   if(InCMD == -1)
     {
      RN_RN = RN_TC;
     }

   if(InCMD == 0)
     {
      RN_RN = RN_Buy;
     }

   if(InCMD == 1)
     {
      RN_RN = RN_Sell;
     }

   return RN_RN;
  }

// standard get InUse Lot
double getInUseLot(int InTradeCount, string InMagicNumber = NULL)
  {
   double RN_GL = 0.01;

   if(InMagicNumber == NULL)
     {
      InMagicNumber = CurrMagicNumber;
     }

// get First Ticket Lot
   double FirstTicketLot = 1000;

   for(int i_GTC = OrdersTotal() -1; i_GTC >= 0; i_GTC --)
     {
      if(OrderSelect(i_GTC,SELECT_BY_POS,MODE_TRADES) == TRUE)
        {
         if(OrderMagicNumber() == StrToInteger(InMagicNumber))
           {
            if(OrderLots() <= FirstTicketLot)
              {
               FirstTicketLot = OrderLots();
              }
           }
        }
     }

   RN_GL = FirstTicketLot * LotFactorList[InTradeCount];

   return RN_GL;
  }

//draw info
void drawInfo()
  {
   DrawLable(1, "d1", "CurrTC: " + IntegerToString(TradeCount(-1))+"-BV: "+IntegerToString(Buy_VirtualLevel)+"-SV"+IntegerToString(Sell_VirtualLevel)
             ,9,30,5+15*1);

   DrawLable(1, "d2","CurrFL: " + DoubleToStr(Quantity,2) + " -InL: " + DoubleToStr(InUseLot,2) + " -CurrSp:"+ DoubleToStr(CurrSpread, 0),9,30,5+15*2);
             
   DrawLable(1, "d3","MN: " + CurrMagicNumber + " -CurrTN: " + IntegerToString(CurrTN) + " -AllowedTN: " +
             IntegerToString(AllowedTN),9,30,5+15*3);
  }

//draw text
void drawText(string xTextName,datetime xInDT,double xInPrice, string xInContent, color xInCrl)
  {
   TextCreate(0,xTextName,0,xInDT,xInPrice,xInContent,"Arial",10,xInCrl);
  }

// standard get MagicNumber
string getMagicNumber(string InLabel)
  {
   string RN_GMN = "InLabel";

   string SymbolPart = "";

   if(CurrSymbol == "AUDUSD")
     {
      SymbolPart = "101";
     }
   if(CurrSymbol == "EURGBP")
     {
      SymbolPart = "102";
     }
   if(CurrSymbol == "USDCHF")
     {
      SymbolPart = "103";
     }
   if(CurrSymbol == "USDJPY")
     {
      SymbolPart = "104";
     }
   if(CurrSymbol == "XAUUSD")
     {
      SymbolPart = "105";
     }
   if(CurrSymbol == "EURUSD")
     {
      SymbolPart = "106";
     }
   if(CurrSymbol == "AUDJPY")
     {
      SymbolPart = "107";
     }
   if(CurrSymbol == "EURJPY")
     {
      SymbolPart = "108";
     }
   if(CurrSymbol == "GBPUSD")
     {
      SymbolPart = "109";
     }
   if(CurrSymbol == "AUDCAD")
     {
      SymbolPart = "110";
     }
   if(CurrSymbol == "AUDNZD")
     {
      SymbolPart = "111";
     }
   if(CurrSymbol == "XAGUSD")
     {
      SymbolPart = "112";
     }
   if(CurrSymbol == "USDCAD")
     {
      SymbolPart = "113";
     }
   if(CurrSymbol == "CADJPY")
     {
      SymbolPart = "114";
     }
   if(CurrSymbol == "NZDCAD")
     {
      SymbolPart = "115";
     }
   if(CurrSymbol == "NZDUSD")
     {
      SymbolPart = "116";
     }
   if(CurrSymbol == "GBPJPY")
     {
      SymbolPart = "117";
     }
   if(CurrSymbol == "GBPNZD")
     {
      SymbolPart = "118";
     }
   if(CurrSymbol == "GBPAUD")
     {
      SymbolPart = "119";
     }
   if(CurrSymbol == "NZDCHF")
     {
      SymbolPart = "120";
     }
   if(CurrSymbol == "AUS200")
     {
      SymbolPart = "121";
     }
   if(CurrSymbol == "XAUAUD")
     {
      SymbolPart = "122";
     }
   if(CurrSymbol == "EURCHF")
     {
      SymbolPart = "123";
     }
   if(CurrSymbol == "EURNZD")
     {
      SymbolPart = "124";
     }
   if(CurrSymbol == "EURCAD")
     {
      SymbolPart = "125";
     }
   if(CurrSymbol == "CHFJPY")
     {
      SymbolPart = "126";
     }
   if(CurrSymbol == "USDSGD")
     {
      SymbolPart = "127";
     }
   if(CurrSymbol == "NZDJPY")
     {
      SymbolPart = "128";
     }
   if(CurrSymbol == "AUDCHF")
     {
      SymbolPart = "129";
     }
   if(CurrSymbol == "CADCHF")
     {
      SymbolPart = "130";
     }

   RN_GMN = InLabel + SymbolPart;

   return (RN_GMN);
  }

//check allowed
string CheckTradeSginalPass_15500_Special()
  {
   string RNTTATT = "Yes";

   if(CurrTN >= AllowedTN)
     {
      RNTTATT = "No";
     }

   return (RNTTATT);
  }

//#endregion

//#MT4 Special
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawWingdingsObject(string InObjName, datetime InTimeAnchor, double InPriceAnchor, color InColour,  int InWingdingsNum)
  {
   ObjectDelete(InObjName) ;

   ObjectCreate(InObjName,OBJ_ARROW,0, InTimeAnchor,InPriceAnchor);

   ObjectSetInteger(0, InObjName,OBJPROP_COLOR, InColour);

   ObjectSetInteger(0,InObjName,OBJPROP_ARROWCODE,InWingdingsNum);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLable(int InDrawConner, string InDrawLable, string InDrawContent, int InFontSize, int InX, int InY, color InColour = Black)
  {
// create the object -----------------------------------------
   ObjectCreate(InDrawLable,OBJ_LABEL,0,0,0);

// set the text for lable
   ObjectSetText(InDrawLable,InDrawContent,InFontSize,"Arial", InColour);

// set the corner
   ObjectSet(InDrawLable, OBJPROP_CORNER,InDrawConner);

// Set the corner x distance
   ObjectSet(InDrawLable, OBJPROP_XDISTANCE,InX);

// Set the corner y distance
   ObjectSet(InDrawLable, OBJPROP_YDISTANCE,InY);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setChartBackground()
  {
   ChartSetInteger(0,CHART_COLOR_BACKGROUND,White);

   ChartSetInteger(0, CHART_COLOR_CHART_UP, SeaGreen) ;

   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, Red) ;

   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, SeaGreen) ;

   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, Red) ;

   ChartSetInteger(0, CHART_SHOW_GRID, false) ;

   ChartSetInteger(0, CHART_COLOR_FOREGROUND, Black) ;
  }

//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create Text object
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar(int period)
  {
   bool firstRun = false, newBar = false;

   ArraySetAsSeries(ArrayTime,true);
   CopyTime(CurrSymbol,period,0,2,ArrayTime);

   if(LastTime == 0)
      firstRun = true;
   if(ArrayTime[0] > LastTime)
     {
      if(firstRun == false)
         newBar = true;
      LastTime = ArrayTime[0];
     }
   return newBar;
  }
//#endregion

//+------------------------------------------------------------------+
