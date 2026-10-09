pragma Ada_2022;
pragma SPARK_Mode (On);
--  Bounded browser history (Capacity pages). Pages 1 .. Length are the
--  history, page Current_Index is shown. Visit drops the pages after the
--  current one and appends the new page; Back and Forward move one step.
package Design_Browser_History is
   Capacity : constant := 4;
   subtype Page is Positive range 1 .. 100;
   subtype Count is Natural range 0 .. Capacity;
   type History is private;

   function Length (H : History) return Count with Global => null;
   function Current_Index (H : History) return Count with Global => null;
   function Page_At (H : History; I : Positive) return Page
     with Global => null, Pre => I <= Length (H);
   --  The I-th page of the history (1 = oldest).

   function Empty return History
     with Global => null,
     Post => Length (Empty'Result) = 0 and then Current_Index (Empty'Result) = 0;

   procedure Visit (H : in out History; P : Page) with Global => null,
     Pre  => Current_Index (H) < Capacity,
     Post => Current_Index (H) = Current_Index (H'Old) + 1
             and then Length (H) = Current_Index (H)
             and then Page_At (H, Current_Index (H)) = P
             and then (for all I in 1 .. Current_Index (H'Old) =>
                         Page_At (H, I) = Page_At (H'Old, I));
   --  Room is needed after the current page (forward pages are dropped).

   procedure Back (H : in out History) with Global => null,
     Pre  => Current_Index (H) > 1,
     Post => Current_Index (H) = Current_Index (H'Old) - 1
             and then Length (H) = Length (H'Old)
             and then (for all I in 1 .. Length (H) =>
                         Page_At (H, I) = Page_At (H'Old, I));

   procedure Forward (H : in out History) with Global => null,
     Pre  => Current_Index (H) < Length (H),
     Post => Current_Index (H) = Current_Index (H'Old) + 1
             and then Length (H) = Length (H'Old)
             and then (for all I in 1 .. Length (H) =>
                         Page_At (H, I) = Page_At (H'Old, I));

   function Current_Page (H : History) return Page with Global => null,
     Pre  => Current_Index (H) > 0,
     Post => Current_Page'Result = Page_At (H, Current_Index (H));
private
   subtype Index is Positive range 1 .. Capacity;
   type Page_Array is array (Index) of Page;
   type History is record
      Pages   : Page_Array := [others => 1];
      Size    : Count := 0;
      Current : Count := 0;
   end record
     with Type_Invariant =>
       History.Current <= History.Size
       and then (History.Current = 0) = (History.Size = 0);
   --  The current page is a stored page; it is 0 only when empty.

   function Length (H : History) return Count is (H.Size);
   function Current_Index (H : History) return Count is (H.Current);
   function Page_At (H : History; I : Positive) return Page is (H.Pages (I));
end Design_Browser_History;
