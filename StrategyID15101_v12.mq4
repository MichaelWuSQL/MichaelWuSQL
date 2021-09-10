/*=============================================================================================================
Michael Wu
Date: 2020-05-09
Log: This script provides EA for strategy 5201

TF: 5 , Mode S2, No. 01

Entry point: RSI higher or lower than threshold (15) in M5 (or M60)

2020-07-15: added SendReceiveMessage and more display info
2020-07-26: add virtual trade component
=============================================================================================================*/


//+------------------------------------------------------------------+
//|                                 Prod_5201[SymbolID]_20200726.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


// include
#include <StandardFunctionVer1.0.mqh>


// Get Version Number
string Version = "20200726" ;

int StrategyNum = 5201 ;


//--- define enum ------------------------------------------------//
enum YesNo
  {
   No=0,
   Yes=1
  };


//--- define keyboard entry --------------------------------------//
#define KEY_NUMLOCK_0     96

#define KEY_NUMLOCK_1     97

#define KEY_NUMLOCK_2     98

#define KEY_NUMLOCK_3     99

#define KEY_NUMLOCK_7     103

#define KEY_NUMLOCK_8     104

#define KEY_NUMLOCK_9     105


//--- input info -----------------------------------------------//
extern double CurrFirstLot = 0.1;

extern int CurrStepPts = 120;

extern int CMD = -1 ;

extern int MaxTradeCount = 16 ;

extern int MaxOneBarTrade = 2;

extern int MaxSpreadAllowed = 20 ;

extern static string CurrSwitch = "On" ;

extern int AllowedNumOfTrade = 3000 ;

extern YesNo IsUsingEquityForFirstLot = No ;

extern YesNo IsClearAllObject = No ;

extern int LotFactorMode = 1 ;

extern int PriceFactorMode = 1 ;

extern int CurrInProcessWaitBar = 3;

extern int CurrCompletionWaitBar = 8 ;


// strategy specific
extern int RSIPeriod = 14 ;

extern double RSILevel = 15;

extern int TriggerTradeLevel = 2;


//--- common info ---------------------------------------------//
string CurrSymbol = "EURUSD" ;

int CurrMagicNumber= 1006106;

int Currdigits = 5 ;

double CurrPtsValue = 0.00001 ;

int CurrPtsToInt = 100000;

int CurrTimeFrame = 5 ;

int UniversalBuffer = 5;

int CurrLogin = 123456;

string CurrComment;

int CurrCAT = 0 ;

int PlaceOrder = 0;

string BrokerName ;

double PriceFactor = 1 ;

double PriceFactor_Virtual = 1;

int CurrSymbolID = 789 ;

int SLTPFactor = 20 ;


//--- static Para -------------------------------------------------//
static int NumOfTradePlaced = 0 ;

static int ActionType = 100 ;

static int CheckBarInt = -1 ;

static int AT100WaitAnchar = -1 ;

static int CurrBarTradePlaced = 0 ;

static string FolComment;


// strategy specific
static double TriggerPrice = 0;

static double OutPrice = 0;

static int VirtualTradeLevel = 0;


//+------------------------------------------------------------------+
//|--  Initialisation                                                |
//+------------------------------------------------------------------+
int OnInit()
  {
   setChartBackground();

   CurrLogin = (int)AccountInfoInteger(ACCOUNT_LOGIN);

   CurrSymbol = _Symbol ;

   string InternalSymbol = StringSubstr(CurrSymbol,0,6); //currently all used symbol has 6 digits

   CurrSymbolID = GetSymbolID(InternalSymbol) ;

   CurrMagicNumber = StrategyNum * 1000 + CurrSymbolID ;

   Currdigits = (int)MarketInfo(CurrSymbol,MODE_DIGITS);

   if(Currdigits == 3)
     {
      CurrPtsValue= 0.001;

      CurrPtsToInt = 1000;
     }

   if(Currdigits == 2)
     {
      CurrPtsValue = 0.01;

      CurrPtsToInt = 100;
     }

   if(Currdigits == 1)
     {
      CurrPtsValue = 0.1;

      CurrPtsToInt = 10;
     }

   BrokerName = AccountInfoString(ACCOUNT_COMPANY);

   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//|-- DeInitialisation                                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(IsClearAllObject == 1)
     {
      ObjectsDeleteAll();
     }
  }


//+------------------------------------------------------------------+
//|-- Main Logic                                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
// prepare parameters
   int CurrentTimeStamp = (int) TimeCurrent();

   CurrComment = IntegerToString(CurrLogin) + IntegerToString(CurrentTimeStamp) ;

   int CurrTimeStamp_LastBar = (int) iTime(CurrSymbol,CurrTimeFrame,1) ;

   if(CurrTimeStamp_LastBar != CheckBarInt)
     {
      CurrBarTradePlaced = 0 ;
     }


// -  set up current price
   double CurrAsk = NormalizeDouble(MarketInfo(CurrSymbol,MODE_ASK), Currdigits);

   double CurrBid = NormalizeDouble(MarketInfo(CurrSymbol,MODE_BID), Currdigits);

   double CurrMid = (CurrAsk + CurrBid)/2;

   int CurrSpreadCheck = (int)MarketInfo(CurrSymbol,MODE_SPREAD);


// - set up trade count and lot info
   int CurrTradeCount= GetTradeCount(CurrMagicNumber,0) + GetTradeCount(CurrMagicNumber,1) ;

   if(IsUsingEquityForFirstLot == 1)
     {
      double CurrEquity = AccountInfoDouble(ACCOUNT_EQUITY);

      CurrFirstLot = GetFirstLotByEquity(CurrEquity) ;
     }

   double CurrLot = CurrFirstLot  ;

   if(CurrTradeCount >= 1)
     {
      CurrLot  = GetIncrementalLotByMN(CurrTradeCount,CurrMagicNumber,LotFactorMode);

      PriceFactor = GetPriceFactor(CurrTradeCount,PriceFactorMode) ;

      CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1) ; // once trade placed , always get last bar timestamp

      ActionType = 400 ;
     }


// - set up all parameters
   double CurrStepPriceBuy =  0;

   double CurrStepPriceSell = 0;

   double CurrTargetPriceBuy = 0 ;

   double CurrTargetPriceSell = 0 ;

   double CurrSafetyPriceBuy = 0;

   double CurrSafteyPriceSell = 0 ;

   double CurrRSI_Main = iRSI(CurrSymbol,CurrTimeFrame, RSIPeriod,0,1);

   int OneSide200EMACount = EMA200Info(0,CurrSymbol,CurrTimeFrame,CurrPtsToInt);

   int PriceEMA200Distance = EMA200Info(1,CurrSymbol,CurrTimeFrame,CurrPtsToInt);

   int Bar200AvgLength = AvgBarLength(CurrSymbol, CurrTimeFrame, CurrPtsToInt);


// AT 100 Wait for 1st BB Outside Bar
   if(ActionType == 100)
     {
      if(CurrRSI_Main <= RSILevel)
        {
         VirtualTradeLevel = 1 ;

         PriceFactor_Virtual = GetPriceFactor(MathAbs(VirtualTradeLevel),PriceFactorMode) ;

         TriggerPrice = CurrMid - CurrStepPts * CurrPtsValue ;

         OutPrice = CurrMid + PriceFactor_Virtual * CurrStepPts * CurrPtsValue ;

         DrawWingdingsObject(IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType) + IntegerToString(VirtualTradeLevel),Time[0],CurrMid,Blue,128+MathAbs(VirtualTradeLevel));

         ActionType = 260 ;

         DrawWingdingsObject(CurrComment + "B",Time[1],Low[1],Blue,133);
        }

      if(CurrRSI_Main >=100- RSILevel)
        {
         VirtualTradeLevel = -1 ;

         PriceFactor_Virtual = GetPriceFactor(MathAbs(VirtualTradeLevel),PriceFactorMode) ;

         TriggerPrice = CurrMid + CurrStepPts * CurrPtsValue ;

         OutPrice = CurrMid - PriceFactor_Virtual * CurrStepPts * CurrPtsValue ;

         DrawWingdingsObject(IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType) + IntegerToString(VirtualTradeLevel),Time[0],CurrMid,Red,128+MathAbs(VirtualTradeLevel));

         ActionType = 261 ;

         DrawWingdingsObject(CurrComment + "S",Time[1],High[1],Red,133);
        }
     }


// AT 260 Virtual trade buy process
   if(ActionType == 260)
     {
      if(MathAbs(VirtualTradeLevel) < TriggerTradeLevel)
        {
         if(CurrMid >= OutPrice)
           {
            DrawWingdingsObject("C" + IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType),Time[0],CurrMid,clrPurple,181);

            CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

            ActionType = 800 ;
           }

         if(CurrMid <= TriggerPrice)
           {
            VirtualTradeLevel = VirtualTradeLevel + 1 ;

            PriceFactor_Virtual = GetPriceFactor(MathAbs(VirtualTradeLevel),3) ;

            TriggerPrice = CurrMid - CurrStepPts * CurrPtsValue ;

            OutPrice = CurrMid + PriceFactor_Virtual * CurrStepPts * CurrPtsValue ;

            DrawWingdingsObject(IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType) + IntegerToString(VirtualTradeLevel),Time[0],CurrMid,Blue,128+MathAbs(VirtualTradeLevel));
           }
        }
      else
        {
         ActionType = 300;
        }
     }


// AT 261 Virtual trade sell process
   if(ActionType == 261)
     {
      if(MathAbs(VirtualTradeLevel) < TriggerTradeLevel)
        {
         if(CurrMid <= OutPrice)
           {
            DrawWingdingsObject("C" + IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType),Time[0],CurrMid,clrPurple,181);

            CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

            ActionType = 800 ;
           }

         if(CurrMid >= TriggerPrice)
           {
            VirtualTradeLevel = VirtualTradeLevel - 1 ;

            PriceFactor_Virtual = GetPriceFactor(MathAbs(VirtualTradeLevel),3) ;

            TriggerPrice = CurrMid + CurrStepPts * CurrPtsValue ;

            OutPrice = CurrMid - PriceFactor_Virtual * CurrStepPts * CurrPtsValue ;

            DrawWingdingsObject(IntegerToString(CurrentTimeStamp) + IntegerToString(ActionType) + IntegerToString(VirtualTradeLevel),Time[0],CurrMid,Red,128+MathAbs(VirtualTradeLevel));
           }
        }
      else
        {
         ActionType = 301;
        }
     }


// AT 300 Buy Action
   if(ActionType == 300)
     {
      if(CurrSwitch == "On" &&  CurrSpreadCheck <= MaxSpreadAllowed && CurrTradeCount == 0 && NumOfTradePlaced < AllowedNumOfTrade && (CMD == 0 || CMD ==-1))
        {
         if(OrderSend_Pts(0,CurrMagicNumber,CurrSymbol,CurrLot, CurrStepPts*SLTPFactor,CurrStepPts*SLTPFactor,CurrAsk,Currdigits,CurrComment)> 0)
           {
            CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

            NumOfTradePlaced = NumOfTradePlaced + 1 ;

            CurrBarTradePlaced = CurrBarTradePlaced + 1 ;

            Print("Order was via Entry Point 300");

            ActionType = 400 ; //AV mode
           }
        }
      else
        {
         CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

         ActionType = 800 ;
        }
     }


// AT 301 Sell Action
   if(ActionType == 301)
     {
      if(CurrSwitch == "On"  &&  CurrSpreadCheck <= MaxSpreadAllowed && CurrTradeCount == 0 && NumOfTradePlaced < AllowedNumOfTrade && (CMD == 1 || CMD ==-1))
        {
         if(OrderSend_Pts(1,CurrMagicNumber,CurrSymbol,CurrLot, CurrStepPts*SLTPFactor,CurrStepPts*SLTPFactor,CurrBid,Currdigits,CurrComment)>0)
           {
            CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

            NumOfTradePlaced = NumOfTradePlaced + 1 ;

            CurrBarTradePlaced = CurrBarTradePlaced + 1 ;

            Print("Order was via Entry Point 301");

            ActionType = 400 ; // AV mode
           }
        }
      else
        {
         CheckBarInt = (int) iTime(CurrSymbol,CurrTimeFrame,1);

         ActionType = 800 ;
        }
     }


// AT 400 AV mode
   if(ActionType == 400)
     {
      int CurrLastTicket = GetLastTradeTicket(CurrMagicNumber);

      if(OrderSelect(CurrLastTicket,SELECT_BY_TICKET) == TRUE)
        {
         FolComment = OrderComment();

         if(OrderType()==0 && OrderMagicNumber() == CurrMagicNumber)
           {
            CurrStepPriceBuy = NormalizeDouble(OrderOpenPrice()-CurrStepPts*CurrPtsValue, Currdigits) ;

            CurrSafetyPriceBuy = NormalizeDouble(OrderOpenPrice()-2*CurrStepPts*CurrPtsValue, Currdigits) ;

            CurrTargetPriceBuy = NormalizeDouble(OrderOpenPrice() + PriceFactor * CurrStepPts*CurrPtsValue, Currdigits) ;

            if(CurrBid >= CurrTargetPriceBuy -1*CurrPtsValue) // Target hit
              {
               CurrCAT = CloseAllTrade(CurrMagicNumber,UniversalBuffer);

               ActionType = 900;  // Trade complete re-set
              }

            if((CurrAsk <= CurrStepPriceBuy + 3*CurrPtsValue && CurrAsk >= CurrStepPriceBuy - 4*UniversalBuffer* CurrPtsValue)
               || CurrAsk <= CurrSafetyPriceBuy)   // StepPrice hit
              {
               if(CurrTradeCount <  MaxTradeCount)
                 {
                  if(CurrBarTradePlaced < MaxOneBarTrade)
                    {
                     PlaceOrder = OrderSend_Pts(0,CurrMagicNumber,CurrSymbol,CurrLot,CurrStepPts*SLTPFactor,CurrStepPts*SLTPFactor,CurrAsk,Currdigits,FolComment);

                     CurrBarTradePlaced = CurrBarTradePlaced + 1 ;

                     Print("Order was via Entry Point 400 - Buy");
                    }
                 }
               else
                 {
                  CurrCAT = CloseAllTrade(CurrMagicNumber,UniversalBuffer);

                  ActionType = 900;  // Trade complete re-set
                 }
              }
           }

         if(OrderType()==1 && OrderMagicNumber() == CurrMagicNumber)
           {
            CurrStepPriceSell = NormalizeDouble(OrderOpenPrice()+CurrStepPts*CurrPtsValue, Currdigits) ;

            CurrSafteyPriceSell = NormalizeDouble(OrderOpenPrice()+2*CurrStepPts*CurrPtsValue, Currdigits) ;

            CurrTargetPriceSell = NormalizeDouble(OrderOpenPrice()- PriceFactor * CurrStepPts*CurrPtsValue, Currdigits) ;

            if(CurrAsk <= CurrTargetPriceSell +1*CurrPtsValue)  // Target hit
              {
               CurrCAT = CloseAllTrade(CurrMagicNumber,UniversalBuffer);

               ActionType = 900;  // Trade complete re-set
              }

            if((CurrBid >= CurrStepPriceSell - 3*CurrPtsValue && CurrBid <= CurrStepPriceSell + 4*UniversalBuffer* CurrPtsValue)
               || CurrBid >= CurrSafteyPriceSell) // StepPrice hit
              {
               if(CurrTradeCount <  MaxTradeCount)
                 {
                  if(CurrBarTradePlaced < MaxOneBarTrade)
                    {
                     PlaceOrder = OrderSend_Pts(1,CurrMagicNumber,CurrSymbol,CurrLot,CurrStepPts*SLTPFactor,CurrStepPts*SLTPFactor,CurrBid,Currdigits,FolComment);

                     CurrBarTradePlaced = CurrBarTradePlaced + 1 ;

                     Print("Order was via Entry Point 400 - Sell");
                    }
                 }
               else
                 {
                  CurrCAT = CloseAllTrade(CurrMagicNumber,UniversalBuffer);

                  ActionType = 900;  // Trade complete re-set
                 }
              }
           }
        }
     }


// AT 800 Pre Trade Completion Re-set || AT 900 Trade Completion Re-set
   if(ActionType == 800 || ActionType == 900)
     {
      if(CurrentTimeStamp  >=  CheckBarInt + 60*CurrTimeFrame* CurrCompletionWaitBar &&  CheckBarInt != -1)   // in seconds -- 60 s * 5m * NoOfWait bars
        {
         ReSetParameter();
        }
     }


// define case ActionType
   string CaseActionTypeTxt ;

   switch(ActionType)
     {
      case 100:
         CaseActionTypeTxt = "Wait for qualified bar" ;
         break;
      case 300:
         CaseActionTypeTxt = "Buy action" ;
         break;
      case 301:
         CaseActionTypeTxt = "Sell action" ;
         break;
      case 400:
         CaseActionTypeTxt = "Average mode" ;
         break;
      case 800:
         CaseActionTypeTxt = "Pre-trade completion re-set" ;
         break;
      case 900:
         CaseActionTypeTxt = "Trade completion re-set" ;
         break;
     }


// Draw info on chart
   double CurrDisplayTargetPrice = 0 ;

   double CurrDisplayStepPrice = 0 ;

   if(CurrTargetPriceBuy > 0)
     {
      CurrDisplayTargetPrice = CurrTargetPriceBuy ;
      CurrDisplayStepPrice = CurrStepPriceBuy ;
     }
   if(CurrTargetPriceSell > 0)
     {
      CurrDisplayTargetPrice = CurrTargetPriceSell ;
      CurrDisplayStepPrice = CurrStepPriceSell ;
     }


// basic info drawing
   int DL1 = DrawLable(1, "L1","Login: "+ IntegerToString(CurrLogin) + " Broker: " + BrokerName,9,30,10);

   int DL2 = DrawLable(1, "L2","Ask: "+ DoubleToString(CurrAsk,Currdigits) + " Bid: "+ DoubleToString(CurrBid,Currdigits),9,30,25);

   int DL3 = DrawLable(1, "L3","Spread: "+ IntegerToString(CurrSpreadCheck) +" pts",9,30,40);

   int DL4 = DrawLable(1, "L4","Sever DT: "+ TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),9,30,55);

   int DL5 = DrawLable(1, "L5","EA Symbol: "+ CurrSymbol + " MagicNum: " + IntegerToString(CurrMagicNumber),9,30,70);

   int DL6 = DrawLable(1, "L6","Current Lot: "+ DoubleToStr(CurrLot,2),9,30,85);


// additional info
   int AdditionalDraw1 = DrawLable(1,"A1","CurrTargetPrice: " + DoubleToStr(CurrDisplayTargetPrice,Currdigits),9,30,100);

   int AdditionalDraw2 = DrawLable(1,"A2","CurrStepPrice: " + DoubleToStr(CurrDisplayStepPrice,Currdigits),9,30,115);

   int AdditionalDraw3 = DrawLable(1, "A3","Current ActionType: "+ IntegerToString(ActionType) + " :" + CaseActionTypeTxt,9,30,130);

   int AdditionalDraw4 = DrawLable(1, "A4","Current TradeCount: "+ IntegerToString(CurrTradeCount),9,30,145);

   int AdditionalDraw5 = DrawLable(1, "A5","Num Of Trade Placed: "+ IntegerToString(NumOfTradePlaced),9,30,160);

   int AdditionalDraw6 = DrawLable(1, "A6","PriceFactor: " + DoubleToStr(PriceFactor,2),9,30,175);

   int AdditionalDrawLine1 = DrawLable(1, "AL1","----------------------------------------",9,15,190);

   int AdditionalDraw7 = DrawLable(1, "A7","OneSide200EMACount: "+ IntegerToString(OneSide200EMACount),9,30,205);

   int AdditionalDraw8 = DrawLable(1, "A8","PriceEMA200Distance: "+ IntegerToString(PriceEMA200Distance),9,30,220);

   int AdditionalDraw9 = DrawLable(1, "A9","Bar200AvgLength: " + IntegerToString(Bar200AvgLength),9,30,235);


//strategy specific
   int AdditionalDrawSS = DrawLable(1, "ASS","----------------------------------------",9,15,250);

   int AdditionalDrawSS1 = DrawLable(1, "ASS1","CurrRSI_Main: " + DoubleToStr(CurrRSI_Main,2),9,30,265);

   int AdditionalDrawSS2 = DrawLable(1, "ASS2","VirtualTradeLevel: " + IntegerToString(VirtualTradeLevel),9,30,280);


// strategy info
   int DrawStrategyID = DrawLable(3, "SID","Strategy: " + IntegerToString(StrategyNum),12,30,30,Red);

   int DrawVersion = DrawLable(3, "Ver","Ver: " + Version,9,30,15,Red);


// parameter drawing
   int DrawInputPara1 = DrawLable(4, "DIP1","CurrSwitch: "+ CurrSwitch,12,560,15, Red);

   int DrawInputPara2 = DrawLable(4, "DIP2","CurrFirstLot: "+ DoubleToStr(CurrFirstLot,2),9,15,15);

   int DrawInputPara3 = DrawLable(4, "DIP3","CurrStepPts: "+ IntegerToString(CurrStepPts),9,15,30);

   int DrawInputPara4 = DrawLable(4, "DIP4","MaxTradeCount: "+ IntegerToString(MaxTradeCount),9,15,45);

   int DrawInputPara5 = DrawLable(4, "DIP5","MaxOneBarTrade: "+ IntegerToString(MaxOneBarTrade),9,15,15* 4);

   int DrawInputPara6 = DrawLable(4, "DIP6","MaxSpreadAllowed: "+ IntegerToString(MaxSpreadAllowed),9,15,15* 5);

   int DrawInputPara7 = DrawLable(4, "DIP7","AllowedNumOfTrade: "+ IntegerToString(AllowedNumOfTrade),9,15,15* 6);

   int DrawInputPara8 = DrawLable(4, "DIP8","CMD: "+ IntegerToString(CMD),9,15,15* 7);

   int DrawInputPara9 = DrawLable(4, "DIP9","IsUsingEquityForFirstLot: "+ IntegerToString(IsUsingEquityForFirstLot),9,15,15* 8);

   int DrawInputPara10 = DrawLable(4, "DIP10","LotFactorMode: "+ IntegerToString(LotFactorMode),9,15,15* 9);

   int DrawInputPara11 = DrawLable(4, "DIP11","PriceFactorMode: "+ IntegerToString(PriceFactorMode),9,15,15* 10);

   int DrawInputPara12 = DrawLable(4, "DIP12","WaitBar InProcess: "+ IntegerToString(CurrInProcessWaitBar) + " Completion: " + IntegerToString(CurrCompletionWaitBar),9,15,15* 11);


// strategy specific
   int DrawInputParaSS = DrawLable(4, "DIPSS","----------------------------------------",9,15,15* 12);

   int DrawInputParaSS1 = DrawLable(4, "DIPSS1","RSIPeriod: " + IntegerToString(RSIPeriod),9,15,15* 13);

   int DrawInputParaSS2 = DrawLable(4, "DIPSS2","RSILevel: " + DoubleToStr(RSILevel,0),9,15,15* 14);

   int DrawInputParaSS3 = DrawLable(4, "DIPSS3","TriggerTradeLevel: " + IntegerToString(TriggerTradeLevel),9,15,15* 15);
  }


//+------------------------------------------------------------------+
//|-- Keyboard control                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   ResetLastError();
   RefreshRates();

   static bool keyPressed=false;

   if(id==CHARTEVENT_KEYDOWN)
     {
      if(lparam==KEY_NUMLOCK_0 || lparam==KEY_NUMLOCK_1 || lparam==KEY_NUMLOCK_2 || lparam==KEY_NUMLOCK_3
         || lparam==KEY_NUMLOCK_7 || lparam==KEY_NUMLOCK_8 || lparam==KEY_NUMLOCK_9)
        {
         if(!keyPressed)
            keyPressed=true;
         else
            keyPressed=false;
        }

      switch(int(lparam))
        {
         case KEY_NUMLOCK_0 :
           {
            Print("Pressed 0");
            CurrSwitch = "On";
           }
         break;

         case KEY_NUMLOCK_1 :
           {
            Print("Pressed 1");
            CurrSwitch = "Off";
           }
         break;

         case KEY_NUMLOCK_2 :
           {
            Print("Pressed 2");
           }
         break;

         case KEY_NUMLOCK_3 :
           {
            Print("Pressed 3");
           }
         break;

         case KEY_NUMLOCK_7 :
           {
            Print("Pressed 7");
            CMD=-1;

           }
         break;

         case KEY_NUMLOCK_8 :
           {
            Print("Pressed 8");
            CMD=0;
           }
         break;

         case KEY_NUMLOCK_9 :
           {
            Print("Pressed 9");
            CMD=1;
           }
         break;
        }
     }
  }


//+------------------------------------------------------------------+
//|-- re-set all parameters                                          |
//+------------------------------------------------------------------+
void ReSetParameter()
  {
   ActionType = 100 ;

   CheckBarInt = -1 ;

   AT100WaitAnchar = -1;

   PriceFactor = 1;


// strategy specific
   TriggerPrice = 0;

   OutPrice = 0;

   VirtualTradeLevel = 0;
  }


//+------------------------------------------------------------------+
