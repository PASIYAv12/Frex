//+------------------------------------------------------------------+
//|                                                   DEMONS_FX_EA.mq5 |
//|                          Build by Machan & ChatGPT (2025)         |
//+------------------------------------------------------------------+
#property strict
input int FastEMA = 20;
input int SlowEMA = 50;
input int RSIPeriod = 14;
input double RSI_BuyMin = 55.0;
input double RSI_SellMax = 45.0;
input double Risk_Percent = 1.0;
input int ATR_Period = 14;
input double ATR_SL_Mult = 2.0;
input double ATR_TP_Mult = 3.0;
input bool Use_Trailing = true;
input double Trail_ATR_Mult = 1.0;
input int Max_Spread_Points = 25;
input bool One_Trade_Per_Symbol = true;
input bool Trade_Long = true;
input bool Trade_Short = true;
input ulong Magic = 550055;

double LotSizeCalc()
{
   double risk_amount = AccountBalance() * Risk_Percent / 100.0;
   double atr = iATR(_Symbol, _Period, ATR_Period, 1);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double stop_loss_points = atr * ATR_SL_Mult / _Point;
   double lot_size = risk_amount / (stop_loss_points * tick_value);
   lot_size = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
                      MathMin(lot_size, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)));
   lot_size = NormalizeDouble(lot_size, (int)SymbolInfoInteger(_Symbol, SYMBOL_VOLUME_DIGITS));
   return lot_size;
}

bool PositionExists()
{
   if (!One_Trade_Per_Symbol) return false;
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (PositionGetSymbol(i) && PositionGetInteger(POSITION_MAGIC) == (long)Magic && PositionGetString(POSITION_SYMBOL) == _Symbol)
         return true;
   }
   return false;
}

void OnTick()
{
   if (PositionExists()) return;
   if (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > Max_Spread_Points) return;

   double emaFast = iMA(_Symbol, _Period, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaSlow = iMA(_Symbol, _Period, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double rsi = iRSI(_Symbol, _Period, RSIPeriod, PRICE_CLOSE, 0);
   double atr = iATR(_Symbol, _Period, ATR_Period, 0);

   if (Trade_Long && emaFast > emaSlow && rsi >= RSI_BuyMin)
   {
      double lot = LotSizeCalc();
      double sl = NormalizeDouble(Bid - atr * ATR_SL_Mult, _Digits);
      double tp = NormalizeDouble(Bid + atr * ATR_TP_Mult, _Digits);
      trade.Buy(lot, _Symbol, Ask, sl, tp, "Buy signal");
   }
   else if (Trade_Short && emaFast < emaSlow && rsi <= RSI_SellMax)
   {
      double lot = LotSizeCalc();
      double sl = NormalizeDouble(Ask + atr * ATR_SL_Mult, _Digits);
      double tp = NormalizeDouble(Ask - atr * ATR_TP_Mult, _Digits);
      trade.Sell(lot, _Symbol, Bid, sl, tp, "Sell signal");
   }

   if (Use_Trailing)
   {
      for (int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if (PositionGetSymbol(i) && PositionGetInteger(POSITION_MAGIC) == (long)Magic)
         {
            double trail = iATR(_Symbol, _Period, ATR_Period, 0) * Trail_ATR_Mult;
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               double newSL = NormalizeDouble(Bid - trail, _Digits);
               if (newSL > PositionGetDouble(POSITION_SL))
                  trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
               double newSL = NormalizeDouble(Ask + trail, _Digits);
               if (newSL < PositionGetDouble(POSITION_SL) || PositionGetDouble(POSITION_SL) == 0.0)
                  trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
            }
         }
      }
   }
}

#include <Trade\Trade.mqh>
CTrade trade;

//+------------------------------------------------------------------+
