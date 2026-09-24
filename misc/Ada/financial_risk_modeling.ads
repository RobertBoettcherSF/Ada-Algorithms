--  Financial Risk Modeling Package Specification
--  Provides types and subprograms to compute market risk metrics,
--  specifically Value at Risk (VaR) and Expected Shortfall (ES).
--  Supports both Historical Simulation and Parametric (Variance-Covariance) methods.

package Financial_Risk_Modeling
  with SPARK_Mode => On
is

   --  Strong typing for domain-specific data
   type Rate is new Long_Float;

   --  Confidence levels in financial modeling are typically between 50% and 99.99%.
   subtype Confidence_Level is Rate range 0.50 .. 0.9999;

   --  Unconstrained array type to hold a sequence of historical returns
   type Return_Array is array (Positive range <>) of Rate;

   --  Exceptions for invalid data situations
   Insufficient_Data : exception;
   Invalid_Argument  : exception;

   --  ========================================================================
   --  Helper Functions (Exposed for Testing and Extended Use)
   --  ========================================================================

   --  Calculates the arithmetic mean of an array of returns.
   function Mean (Returns : Return_Array) return Rate
     with Pre   => Returns'Length > 0,
          Post  => (if Returns'Length = 1 then Mean'Result = Returns (Returns'First)),
          Global => null;

   --  Calculates the sample standard deviation of an array of returns.
   function Standard_Deviation (Returns : Return_Array) return Rate
     with Pre   => Returns'Length > 1,
          Post  => Standard_Deviation'Result >= 0.0,
          Global => null;

   --  Approximates the inverse Cumulative Distribution Function (CDF)
   --  of the standard normal distribution for a given probability P.
   function Normal_Inverse_CDF (P : Confidence_Level) return Rate
     with Global => null;

   --  Calculates the Probability Density Function (PDF) of the standard normal distribution.
   function Normal_PDF (X : Rate) return Rate
     with Global => null;

   --  ========================================================================
   --  Risk Modeling Variants
   --  ========================================================================

   --  Calculates Value at Risk (VaR) using Historical Simulation.
   --  Finds the empirical quantile corresponding to the confidence level.
   function Historical_VaR (Returns : Return_Array; Confidence : Confidence_Level) return Rate
     with Pre    => Returns'Length > 0,
          Global => null;

   --  Calculates Expected Shortfall (ES) using Historical Simulation.
   --  Averages all returns that fall below the Historical VaR threshold.
   function Historical_ES (Returns : Return_Array; Confidence : Confidence_Level) return Rate
     with Pre    => Returns'Length > 0,
          Global => null;

   --  Calculates Value at Risk (VaR) using the Parametric (Variance-Covariance) method.
   --  Assumes returns are normally distributed.
   function Parametric_VaR (Returns : Return_Array; Confidence : Confidence_Level) return Rate
     with Pre    => Returns'Length > 1,
          Global => null;

   --  Calculates Expected Shortfall (ES) using the Parametric method.
   --  Computes the analytical expected value of the normal distribution tail.
   function Parametric_ES (Returns : Return_Array; Confidence : Confidence_Level) return Rate
     with Pre    => Returns'Length > 1,
          Global => null;

end Financial_Risk_Modeling;
