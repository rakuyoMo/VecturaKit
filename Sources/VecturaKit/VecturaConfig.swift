import Foundation

/// Configuration options for Vectura vector database.
public struct VecturaConfig: Sendable {

  /// The name of the database instance.
  public let name: String

  /// A custom directory where the database should be stored.
  /// Will be created if it doesn't exist, database contents are stored in a subdirectory named after ``name``.
  public let directoryURL: URL?

  /// The dimension of vectors to be stored. If nil, will be auto-detected from the model.
  public let dimension: Int?

  /// Options for similarity search.
  public struct SearchOptions: Sendable {
    /// The default number of results to return.
    public var defaultNumResults: Int = 10

    /// The minimum similarity threshold.
    public var minThreshold: Float?

    private var _hybridWeight: Float = 0.5

    /// Weight for vector similarity in hybrid search (0.0-1.0)
    /// BM25 weight will be (1-hybridWeight)
    /// Values outside the range will be clamped to [0.0, 1.0]
    public var hybridWeight: Float {
      get { _hybridWeight }
      set { _hybridWeight = max(0.0, min(1.0, newValue)) }
    }

    /// BM25 parameters
    public var k1: Float = 1.2
    public var b: Float = 0.75

    /// BM25 score normalization factor. BM25 scores are divided by this value
    /// to normalize them to a 0-1 range for hybrid search. Adjust based on
    /// your corpus size and typical BM25 score ranges.
    public var bm25NormalizationFactor: Float = 10.0

    public init(
      defaultNumResults: Int = 10,
      minThreshold: Float? = nil,
      hybridWeight: Float = 0.5,
      k1: Float = 1.2,
      b: Float = 0.75,
      bm25NormalizationFactor: Float = 10.0
    ) {
      self.defaultNumResults = defaultNumResults
      self.minThreshold = minThreshold
      self._hybridWeight = max(0.0, min(1.0, hybridWeight))
      self.k1 = k1
      self.b = b
      self.bm25NormalizationFactor = bm25NormalizationFactor
    }
  }

  /// Search configuration options.
  public var searchOptions: SearchOptions

  public init(
    name: String,
    directoryURL: URL? = nil,
    dimension: Int? = nil,
    searchOptions: SearchOptions = SearchOptions()
  ) {
    self.name = name
    self.directoryURL = directoryURL
    self.dimension = dimension
    self.searchOptions = searchOptions
  }

}
