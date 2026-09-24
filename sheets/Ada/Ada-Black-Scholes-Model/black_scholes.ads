package Black_Scholes
   with SPARK_Mode => On
is
   -- Strong typing for domain specific values
   type Money is new Long_Float range 0.0 .. Long_Float'Last;
   subtype Positive_Money is Money range 1.0E-8 .. Money'Last;

   type Years is new Long_Float range 0.0 .. Long_Float'Last;
   
   type Rate is new Long_Float;
   type Yield is new Long_Float;

   type Volatility is new Long_Float range 1.0E-8 .. Long_Float'Last;

   type Greek is new Long_Float;

   -- Exception raised when Greeks are calculated at Expiration (T=0)
   -- since time derivatives and volatility sensitivities approach infinite limits.
   Maturity_Expired : exception;

   -- European Call Option Price
   function Call_Price (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Money
     with Global => null,
          Post   => Call_Price'Result >= 0.0;

   -- European Put Option Price
   function Put_Price (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Money
     with Global => null,
          Post   => Put_Price'Result >= 0.0;

   -- Greeks

   -- Delta measures the rate of change of the theoretical option value
   -- with respect to changes in the underlying asset's price.
   function Call_Delta (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   function Put_Delta (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   -- Gamma measures the rate of change in the delta with respect to changes
   -- in the underlying price. Gamma is identical for European calls and puts.
   function Gamma (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   -- Vega measures sensitivity to volatility. Vega is identical for European calls and puts.
   function Vega (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   -- Theta measures the sensitivity of the value of the derivative to the passage of time.
   function Call_Theta (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   function Put_Theta (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   -- Rho measures sensitivity to the interest rate.
   function Call_Rho (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

   function Put_Rho (
      S : Positive_Money;
      K : Positive_Money;
      T : Years;
      R : Rate;
      V : Volatility;
      Q : Yield := 0.0
   ) return Greek
     with Global => null;

end Black_Scholes;
