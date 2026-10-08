with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package BWT is

   -- Custom strong type for indices, distinguishing them from standard integers
   type Index_Type is new Natural;

   -- Record to hold the result of the Index-based BWT variant
   type BWT_Result is record
      Transformed_String : Unbounded_String;
      Primary_Index      : Index_Type;
   end record;

   -- =========================================================================
   -- Variant 1: BWT using Primary Index
   -- This variant avoids adding an EOF marker by returning the row index
   -- of the original string in the sorted rotation table.
   -- =========================================================================
   function Transform (Input : String) return BWT_Result;
   function Inverse_Transform (Input : String; Primary_Index : Index_Type) return String;

   -- =========================================================================
   -- Variant 2: BWT using EOF Marker
   -- This variant appends a unique End-Of-File (EOF) marker to the string.
   -- The marker must NOT be present in the original input string.
   -- =========================================================================
   function Transform_Marker (Input : String; Marker : Character := '$') return String;
   function Inverse_Transform_Marker (Input : String; Marker : Character := '$') return String;

   -- =========================================================================
   -- Exceptions for edge case handling and robustness
   -- =========================================================================
   Invalid_Marker   : exception; -- Raised if marker already exists in input
   Invalid_Input    : exception; -- Raised on bad Primary Index or multiple markers
   Marker_Not_Found : exception; -- Raised if marker is missing during inverse

end BWT;
