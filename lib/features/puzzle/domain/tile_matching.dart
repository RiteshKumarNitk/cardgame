/// Whether dropping the 1-based [pieceIndex] onto the 0-based [slotIndex]
/// is correct. Shared by every "match numbered image tiles" board —
/// regular levels and the Daily Challenge alike — so the one rule they
/// have in common isn't duplicated between their cubits.
bool isCorrectPlacement(int pieceIndex, int slotIndex) =>
    pieceIndex - 1 == slotIndex;
