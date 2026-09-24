-- Clean-room educational economy: mines → steady income; research from steady only.
-- Mission rewards are separate and must not fund research.

with Corp_Profile;

package Economy is

   type Credits is range 0 .. 2_000_000_000;

   Income_Per_Mine : constant Credits := 100;

   type State is record
      Mines           : Natural := 0;
      Steady_Income   : Credits := 0;
      Mission_Rewards : Credits := 0;
      Research_Budget : Credits := 0;
      Treasury        : Credits := 0;
   end record;

   procedure Recalc_Steady_Income
     (S : in out State; P : Corp_Profile.Profile);

   -- Research budget may only be drawn from steady income (not mission rewards).
   procedure Set_Research_Budget (S : in out State; Amount : Credits)
     with Pre => Amount <= S.Steady_Income;

   procedure Add_Mission_Reward (S : in out State; Amount : Credits);

   function Research_From_Steady_Only (S : State) return Boolean;

end Economy;
