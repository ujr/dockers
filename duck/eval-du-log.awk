#!/usr/bin/awk -f
# Evaluate a <year> <month> <mday> <xbytes> disk usage log
# Usage: eval-du-log [free=N] [cost=K] <logfile>

BEGIN { if (!cost) cost = 1
  mon["01"] = "Januar"; mon["02"] = "Februar"; mon["03"] = "Maerz"
  mon["04"] = "April"; mon["05"] = "Mai"; mon["06"] = "Juni"
  mon["07"] = "Juli"; mon["08"] = "August"; mon["09"] = "September"
  mon[10] = "Oktober"; mon[11] = "November"; mon[12] = "Dezember"
  print "#year month load cost"
}

{ mbytes = $4
  year = $1; month = $2
  tot[year,month] += mbytes
  cnt[year,month] += 1
}

END { for (s in tot) A[++n] = s
  isort(A, n) # sort by year then month
  for (i = 1; i <= n; i++) {
    split(A[i], a, SUBSEP)
    y = a[1]; m = a[2]
#    print "** y=" y ", m=" m ", tot=" tot[y,m] ", cnt=" cnt[y,m]
    d = tot[y,m]/cnt[y,m]
    c = (d - free) * cost
    printf "%s %s %.03f %.02f\n", y, mon[m], d, c
  }
}

# Insertion sort of A[1..n] (from AWK man page)
function isort(A, n,   i, j, hold)
{
  for (i = 2; i <= n; i++)
  {
    hold = A[j=i]
    while (A[j-1] > hold)
    { j--; A[j+1] = A[j] }
    A[j] = hold
  }
  # sentinel A[0] = "" will be created if needed
}
