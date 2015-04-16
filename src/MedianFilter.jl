module MedianFilter

export medfilt1

# ord = <  -> max-heap
# ord = >= -> min-heap

function heapify(n,i,f,swap,ord)
    l = 2*i
    r = 2*i+1
    if r <= n
        m = ord(f(r),f(l)) ? l : r
        if ord(f(i),f(m))
            swap(i,m)
            heapify(n,m,f,swap,ord)
        end
    elseif l == n && ord(f(i),f(l))
        swap(i,l)
    end
end

function bubble(n,i,f,swap,ord)
    if i <= 1
        return
    end
    m = div(i,2)
    if ord(f(m),f(i))
        swap(i,m)
        bubble(n,m,f,swap,ord)
    end
end

swp(a,i,j) = a[i],a[j]=a[j],a[i]

type MedHeap
    a
    ord
    f
    swap
    MedHeap(a,ord,values,lookup) = (m = new(a,ord);
        m.f = i -> values[m.a[i]];
        m.swap = (i,j) -> (swp(a,i,j); swp(lookup,m.a[i],m.a[j]));
        m
    )
end

loheap(w,values,lookup) = MedHeap(collect(1:div(w,2)),<,values,lookup)
hiheap(w,values,lookup) = MedHeap(collect(div(w,2)+1:w),>=,values,lookup)

heapify(h::MedHeap,i) = heapify(length(h.a),i,h.f,h.swap,h.ord)
bubble(h::MedHeap,i) = bubble(length(h.a),i,h.f,h.swap,h.ord)
# previous value x at i was replaced
function replaced(h,x,i)
    if h.ord(h.f(i),x)
        heapify(h,i)
    else
        bubble(h,i)
    end
end
top(h::MedHeap) = h.f(1)

type Med{T}
    # value buffer
    values::Vector{T}
    # lookup to heaps
    lookup::Vector{Int}
    # rolling index to values and lookup buffers
    index::Int
    # max heap
    lo::MedHeap
    # min heap
    hi::MedHeap
    Med(x::T,w) = (m = new(fill(x,w),collect(1:w),1);
        m.lo = loheap(w,m.values,m.lookup);
        m.hi = hiheap(w,m.values,m.lookup);
        m)
end

Med{T}(x::T,w) = Med{T}(x,w)

function push_med{T}(m::Med{T},x::T)
    # leaving value
    v = m.values[m.index]
    # current index in heap
    i = m.lookup[m.index]
    n = length(m.lo.a)
    # replace with incoming value
    m.values[m.index] = x
    # check which heap was modified
    a,b,j = i > n ? (m.hi,m.lo,i-n) : (m.lo,m.hi,i)
    # fix heap
    replaced(a,v,j)
    # check if top elements should be swapped
    if top(m.lo) > top(m.hi)
        m.lo.a[1],m.hi.a[1] = m.hi.a[1],m.lo.a[1]
        swp(m.lookup,m.lo.a[1],m.hi.a[1])
        heapify(b,1)
    end
    m.index = m.index == length(m.values) ? 1 : m.index+1
    # return current median
    bool(length(m.values) & 1) ? top(m.hi) : (top(m.lo) + top(m.hi))/2
end

function medfilt1(x,w)
    n = length(x)
    m = Med(x[1],w)
    w1 = div(w,2)
    for i = 1:w1-1
        push_med(m,x[i>n?n:i])
    end
    [push_med(m,x[i+w1>n?n:i+w1]) for i=1:n]
end

end # module
