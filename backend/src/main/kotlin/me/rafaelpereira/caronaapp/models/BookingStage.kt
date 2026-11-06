package me.rafaelpereira.caronaapp.models

/**
 * Situação da vaga do ponto de vista do passageiro, calculada a partir da [Booking] e da [Ride].
 * Só [COMPLETED] conta como viagem feita: quem não embarcou, cancelou ou não confirmou nunca aparece como concluído.
 */
enum class BookingStage {
    /** Vaga reservada; a confirmação de presença ainda não abriu. */
    RESERVED,

    /** Dentro da janela de confirmação, esperando o passageiro dizer se vai. */
    AWAITING_CONFIRMATION,

    /** Passageiro confirmou que vai e já tem o código de embarque. */
    CONFIRMED,

    /** O motorista conferiu o código: o passageiro está no carro. */
    BOARDED,

    /** Viagem concluída com o passageiro a bordo. */
    COMPLETED,

    /** Viagem concluída sem o passageiro ter embarcado. */
    NO_SHOW,

    /** Passageiro não confirmou a presença a tempo e perdeu a vaga. */
    NOT_CONFIRMED,

    /** Passageiro avisou que não vai. */
    CANCELLED,

    /** O motorista cancelou a carona. */
    RIDE_CANCELLED
}
